import { ajax } from '../utils/ajax.js';
import { BBC } from '../utils/bbcode.js';
import { initFileSelect } from './fileinput.js';
import { TagEditor } from './tageditor.js';
import { ThumbPicker } from './thumbnailpicker.js';
import { resizeFont } from '../ui/resize.js';
import { focusTab } from '../ui/tabset.js';
import { toBool, extendObj } from '../utils/misc.js';
import { Player } from './videos.js';
import { jSlim } from '../utils/jslim.js';

const INSTANCES = [];
let INDEX = 0;

const uploadingQueue = {
  running: false,
  items: [],
  enqueue(me) {
    if (me.isReady()) {
      this.items.push(me);
      return this.poke();
    }
  },
  enqueueAll(args) {
    this.items.push.apply(this.items, args);
    return this.poke();
  },
  poke() {
    if (this.running) return;
    this.running = true;
    return this.tick(() => {
      let i = 0;
      while (this.items.length > 0 && !(i = this.items.shift()).isReady());
      if (i && i.isReady()) return i;
    });
  },
  tick(next) {
    const uploader = next();
    this.running = !!uploader;
    if (this.running) {
      uploader.tab.classList.add('loading');
      uploader.tab.classList.add('waiting');
      ajax.form($(uploader.form), {
        success: (data) => {
          uploader.complete(data.ref);
          if (next) next = this.tick(next);
        },
        error: (message, msg, response) => {
          uploader.error();
          message.text(response);
        },
        update: (e, percentage) => {
          uploader.update(percentage);
          if (next && percentage > 100) next = this.tick(next);
        },
      });
    }
    return 0;
  }
};

function Validator(el) {
  this.el = el;
  
  this.hasCover = false;
  this.needsCover = toBool(el.dataset.needsCover);
  
  this.el.notify = this.el.querySelector('.notify');
  this.el.notify.bobber = this.el.notify.querySelector('.bobber');
  this.el.info = this.el.querySelector('.info');
  
  this.time = this.el.querySelector('#time');
  this.lastTime = -1;
  
  this.cover = this.el.querySelector('#cover-upload');
  this.cover.input = this.cover.querySelector('input[type=file]');
  this.cover.preview = this.cover.querySelector('.preview');
  
  this.video = this.el.querySelector('#video-upload');
  this.video.input = this.video.querySelector('input[type=file]');
  
  // Interact with jquery elements
  $(this.video).on('accept', (e, file) => {
    this.needsCover = !!file.mime.match(/audio\//);
    this.accept(file);
  });
  
  $(this.cover).on('accept', () => {
    this.hasCover = true;
    this.validateInput();
  });
  
  const thumbPicker = this.el.querySelector('.tab[data-tab="thumbpick"]');
  
  $(thumbPicker).on('tabblur', () => {
    this.lastTime = this.time.value;
    this.time.value = -1;
    this.validateInput();
  });
  
  $(thumbPicker).on('tabfocus', () => {
    this.time.value = this.lastTime;
    this.validateInput();
  });
}
Validator.prototype = {
  isReady() {
    return this.hasFile && (this.hasCover || !this.needsCover) && this.ready;
  },
  notify(msg) {
    this.el.notify.classList.add('shown');
    this.el.notify.bobber.textContent = msg;
  },
  info(msg) {
    this.el.info.style.display = '';
    this.el.info.textContent = msg;
  }
};

function Uploader() {
  this.id = INDEX++;
  
  // Create new upload form from template
  this.el = document.querySelector('#template').firstElementChild.cloneNode(true);
  this.el.dataset.tab = this.el.dataset.tab.replace(/\{id\}/g, this.id);
  this.el.innerHTML = this.el.innerHTML.replace(/\{id\}/g, this.id);
  
  // Unselect prior tab and insert
  const selectedTab = document.querySelector('#uploader_frame > .tab.selected');
  if (selectedTab) selectedTab.classList.remove('selected');
  document.querySelector('#uploader_frame').appendChild(this.el);
  
  // FIXME template
  const markup = '<li data-target="new[' + this.id + ']" class="button hidden">\
    <span class="progress">\
      <span class="fill"></span>\
    </span>\
    <span class="label">untitled' + (this.id > 0 ? ' ' + this.id : '') + '</span>\
    <i class="fa fa-close"></i>\
  </li>';
  document.querySelector('#new_tab_button').insertAdjacentHTML('beforebegin', markup);
  this.tab = document.querySelector('[data-target="new[' + this.id + ']"');
  
  this.tab.label = this.tab.querySelector('.label');
  this.tab.progress = this.tab.querySelector('.progress');
  this.tab.progress.fill = this.tab.progress.querySelector('.fill');
  
  this.form = this.el.querySelector('form');
  this.videoTitle = this.el.querySelector('#video_title');
  this.videoTitle.input = this.videoTitle.querySelector('input');
  this.videoDescription = this.el.querySelector('textarea.comment-content');
  this.title = this.el.querySelector('#video_title .content');
  this.tagEditor = TagEditor.getOrCreate(this.el.querySelector('.tag-editor'));
  
  this.source = this.el.querySelector('#video_source');
  this.srcNeeded = false;
  
  BBC.init(this.videoTitle);
  
  this.video = this.el.querySelector('#video-upload');
  this.cover = this.el.querySelector('#cover-upload');
  
  initFileSelect(this.video);
  initFileSelect(this.cover);
  
  // FIXME
  requestAnimationFrame(() => this.tab.classList.remove('hidden'));
  
  // Close button click
  this.tab.querySelector('i').addEventListener('click', () => this.dispose);
  this.form.addEventListener('submit', event => {
    uploadingQueue.enqueue(this);
    event.preventDefault();
    event.stopPropagation();
  });
  
  const newVideo = this.el.querySelector('#new_video');
  newVideo.addEventListener('tagschange', () => this.validateInput());
  newVideo.addEventListener('change', event => {
    if (event.target.matches('h1#video_title input')) this.validateInput();
  });
  
  [].forEach.call(this.el.querySelectorAll('h1.resize-target'), t => resizeFont($(t)));
  
  Validator.call(this, this.el);
  
  focusTab($(this.tab));
  
  INSTANCES.push(this);
}
Uploader.uploadAll = function() {
  uploadingQueue.enqueueAll(INSTANCES);
};
Uploader.prototype = extendObj({
  initPlayer() {
    this.player = new ThumbPicker();
    this.player.constructor($(this.el.querySelector('.video')));
  },
  showUI(title) {
    [].forEach.call(this.el.querySelectorAll('.hidden'), e => {
      e.classList.remove('hidden')
    });
    [].forEach.call(this.el.querySelectorAll('.shown'), e => {
      e.classList.add('hidden');
      e.classList.remove('shown');
    });
    
    this.tab.label.textContent = title;
  },
  accept(file) {
    const thumbUpload = this.el.querySelector('li[data-target="thumbupload_' + this.id + '"]');
    const thumbPick = this.el.querySelector('li[data-target="thumbpick_' + this.id + '"]');
    
    if (this.video.classList.contains('shown')) {
      const title = this.cleanup(file.title);
      this.title.textContent = title;
      this.videoTitle.input.value = title;
      this.showUI(file.title + '.' + file.type);
    }
    
    if (!this.player) this.initPlayer();
    
    if (this.needsCover) {
      this.player.load(null);
      thumbUpload.click();
      thumbPick.dataset.disabled = '1';
    } else {
      if (Player.canPlayType(file.mime)) {
        this.player.load(file.data);
        thumbPick.removeAttribute('data-disabled');
        thumbPick.click();
      } else {
        thumbUpload.click();
        thumbPick.dataset.disabled = '1';
      }
    }
    
    this.hasFile = true;
    this.validateInput();
  },
  cleanup(title) {
    // 1. Convert everything to lowercase
    // 2. Remove any beginning digit strings
    // 3. Replace non-alpha/non-whitespace with a single space
    // 4. Convert first letters to uppercase
    // 5. Strip whitespace (FIXME: shouldn't this be first?)
    return title.toLowerCase().replace(/^[0-9]*/g, '').replace(/[-_]|[^a-z\s]/gi, ' ').replace(/(^|\s)[a-z]/g, i => i.toUpperCase()).trim();
  },
  validateInput() {
    const title = this.videoTitle.input.value;
    this.ready = false;
    
    if (!title) return this.notify('You need to provide a title.');
    if (this.needsCover && !this.hasCover) return this.notify('Audio files require a cover image.');
    
    const tags = this.tagEditor.tags.map(t => t.name.trim().toLowerCase());
    const src = this.source.value;
    
    if (!src) {
      this.srcNeeded = false;
      
      // FIXME: Polyfill Array.prototype.includes for IE
      if (tags.indexOf('source needed') !== -1) {
        this.srcNeeded = true;
      }
      
      if (!this.srcNeeded) {
        this.info('You have not provided a source. If you know what it is add it to the source field, otherwise consider tagging this video as \'source needed\' so others know to search for one.');
      } else {
        this.el.info.style.display = 'none';
      }
    } else {
      this.el.info.style.display = 'none';
    }
    
    if (tags.length === 0) return this.notify('You need at least one tag.');
    // FIXME: Is this validation even worth including?
    if (tags.length === 1 && tags[0] === 'music') return this.notify('\'music\' is implied. Tags should be more specific than that. Do you perhaps know who the artist is?');
    this.ready = true;
    this.el.notify.classList.remove('shown');
  },
  update(percentage) {
    this.tab.classList.add('uploading');
    this.tab.progress.fill.style.width = percentage;
    if (percentage >= 100) this.tab.classList.add('waiting');
  },
  complete(ref) {
    this.form.classList.remove('uploading');
    this.tab.classList.remove('uploading');
    this.ready = false;
    
    if (this.tab.classList.contains('selected')) {
      const otherTab = this.tab.parentNode.querySelector('li.button:not([data-disabled]):not(.hidden)[data-target]:not([data-target="' + this.id + '"])');
      if (otherTab) focusTab($(otherTab));
    }
    
    if (ref) {
      this.el.innerHTML = 'Uploading Complete. You can see your new video over <a target="_blank" href="' + ref + '">here</a>.';
    }
  },
  error() {
    this.tab.classList.add('error');
  },
  dispose() {
    INSTANCES.splice(INSTANCES.indexOf(this), 1);
  }
}, Validator.prototype);

jSlim.ready(() => {
  const button = document.querySelector('#new_tab_button');
  if (button) {
    button.addEventListener('click', event => event.button === 0 && new Uploader());
  }
});

function UploadChecker(el) {
  Validator.call(this, el);
  if (this.needsCover) {
    this.initPlayer();
  }
}
UploadChecker.prototype = extendObj({
  initPlayer() {
    this.player = new ThumbPicker();
    this.player.constructor($(this.el.querySelector('.video')));
    this.player.start();
  },
  accept(file) {
    const thumbPick = this.el.querySelector('li[data-target="thumbpick"]');
    const thumbUpload = this.el.querySelector('li[data-target="thumbupload"]');
    
    if (this.needsCover && !this.player) this.initPlayer();
    if (Player.canPlayType(file.mime)) {
      this.player.load(file.data);
      thumbPick.removeAttribute('data-disabled');
      thumbPick.click();
    } else {
      thumbUpload.click();
      thumbPick.dataset.disabled = '1';
    }
    
    this.validateInput();
  },
  validateInput() {
    if (this.needsCover && !this.hasCover) return this.notify('Audio files require a cover image.');
    this.el.notify.classList.remove('shown');
  }
}, Validator.prototype);

Uploader.createChecker = function(el) {
  return new UploadChecker(el);
};

// video/edit.html.erb
// video/upload.html.erb
window.Uploader = Uploader;