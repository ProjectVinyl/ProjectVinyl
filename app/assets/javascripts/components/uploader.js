import { uploadForm } from '../utils/progressform';
import { getTagEditor } from './tageditor';
import { ThumbPicker } from './thumbnailpicker';
import { resizeFont } from '../ui/resize';
import { focusTab } from '../ui/tabset';
import { extendObj } from '../utils/misc';
import { canPlayType } from '../utils/videos';
import { all } from '../jslim/dom';
import { ready } from '../jslim/events';
import { Validator } from './validator';
import { UploadQueue } from './uploadqueue';

const INSTANCES = [];
let INDEX = 0;
let uploadingQueue = null;

function tabMarkup(id) {
  return document.getElementById('tab-template').innerHTML.replace(/\{index\}/g, id || '').replace(/\{id\}/g, id);
}

function uploaderMarkup(id) {
  const result = document.getElementById('template').firstElementChild.cloneNode(true);
  result.innerHTML = result.innerHTML.replace(/\{id\}/g, id);
  result.dataset.tab = result.dataset.tab.replace(/\{id\}/g, id);
  return result;
}

function Uploader() {
  this.id = INDEX++;
  
  // Create new upload form from template
  this.el = uploaderMarkup(this.id);
  
  // Unselect prior tab and insert
  const selectedTab = document.querySelector('#uploader_frame > .tab.selected');
  if (selectedTab) selectedTab.classList.remove('selected');
  document.getElementById('uploader_frame').appendChild(this.el);
  
  document.getElementById('new_tab_button').insertAdjacentHTML('beforebegin', tabMarkup(this.id));
  
  this.tab = document.querySelector(`[data-target="new[${this.id}]"`);
  
  this.tab.label = this.tab.querySelector('.label');
  this.tab.progress = this.tab.querySelector('.progress');
  this.tab.progress.fill = this.tab.progress.querySelector('.fill');
  
  this.form = this.el.querySelector('form');
  this.videoTitle = this.el.querySelector('#video_title');
  this.videoTitle.input = this.videoTitle.querySelector('input');
  this.videoDescription = this.el.querySelector('textarea.comment-content');
  this.title = this.videoTitle.querySelector('.content');
  
  this.tagEditor = getTagEditor(this.el.querySelector('.tag-editor'));
  
  this.source = this.el.querySelector('#video_source');
  this.srcNeeded = false;
  
  // FIXME
  requestAnimationFrame(() => this.tab.classList.remove('hidden'));
  
  // Close button click
  this.tab.querySelector('i').addEventListener('click', () => this.dispose());
  this.form.addEventListener('submit', event => {
    if (!uploadingQueue) uploadingQueue = new UploadQueue();
    uploadingQueue.enqueue(this);
    event.preventDefault();
    event.stopImmediatePropagation();
  });
  
  const newVideo = this.el.querySelector('#new_video');
  const thumbPicker = this.el.querySelector(`.tab[data-tab="thumbpick_${this.id}"]`);
  
  newVideo.addEventListener('tagschange', () => {
    this.validateInput();
  });
  
  newVideo.addEventListener('change', event => {
    if (event.target.matches('h1#video_title input')) {
      this.validateInput();
    }
  });
  
  thumbPicker.addEventListener('tabblur', () => {
    this.lastTime = this.time.value;
    this.time.value = -1;
    this.validateInput();
  });
  
  thumbPicker.addEventListener('tabfocus', () => {
    this.time.value = this.lastTime;
    this.validateInput();
  });
  
  all(this.el, 'h1.resize-target', resizeFont);
  
  Validator.call(this, this.el);
  focusTab(this.tab);
  
  INSTANCES.push(this);
}
Uploader.prototype = extendObj({
  initPlayer: function() {
    this.player = new ThumbPicker();
    this.player.constructor(this.el.querySelector('.video'));
  },
  showUI: function(title) {
    all(this.el, '.ui.hidden', e => {
      e.classList.remove('hidden');
    });
    all(this.el, '.ui.shown', e => {
      e.classList.add('hidden');
      e.classList.remove('shown');
    });
    
    this.tab.label.textContent = title;
  },
  accept: function(file) {
    const thumbUpload = this.el.querySelector(`li[data-target="thumbupload_${this.id}"]`);
    const thumbPick = this.el.querySelector(`li[data-target="thumbpick_${this.id}"]`);
    
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
      if (canPlayType(file.mime)) {
        this.player.load(file.data, true);
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
  cleanup: function(title) {
    // 1. Convert everything to lowercase
    // 2. Remove any beginning digit strings
    // 3. Replace non-alpha/non-whitespace with a single space
    // 4. Convert first letters to uppercase
    // 5. Strip whitespace (FIXME: shouldn't this be first?)
    return title.toLowerCase().replace(/^[0-9]*/g, '').replace(/[-_]|[^a-z\s]/gi, ' ').replace(/(^|\s)[a-z]/g, i => i.toUpperCase()).trim();
  },
  validateInput: function() {
    const title = this.videoTitle.input.value;
    this.ready = false;
    
    if (!title) return this.notify('You need to provide a title.');
    if (this.needsCover && !this.hasCover) return this.notify('Audio files require a cover image.');
    
    const tags = this.tagEditor.tags.baked();
    
    if (!this.source.value) {
      this.srcNeeded = false;
      
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
    // people used to tag their videos with 'music' and nothing else. I wanted to discourage that behaviour...
    if (tags.length === 1 && tags[0] === 'music') {
      return this.notify('\'music\' is implied. Tags should be more specific than that. Do you perhaps know who the artist is?');
    }
    
    this.ready = true;
    this.el.notify.classList.remove('shown');
  },
  update: function(percentage) {
    this.tab.classList.add('uploading');
    this.tab.progress.fill.style.width = percentage;
    if (percentage >= 100) this.tab.classList.add('waiting');
  },
  complete: function(ref) {
    this.form.classList.remove('uploading');
    this.tab.classList.remove('uploading');
    this.ready = false;
    
    if (this.tab.classList.contains('selected')) {
      const otherTab = this.tab.parentNode.querySelector(`li.button:not([data-disabled]):not(.hidden)[data-target]:not([data-target="${this.id}"])`);
      if (otherTab) focusTab(otherTab);
    }
    
    if (ref) {
      this.el.innerHTML = `Uploading Complete. You can see your new video over <a target="_blank" href="${ref}">here</a>.`;
    }
  },
  error: function() {
    this.tab.classList.add('error');
  },
  dispose: function() {
    INSTANCES.splice(INSTANCES.indexOf(this), 1);
  }
}, Validator.prototype);

ready(() => {
  const button = document.getElementById('new_tab_button');
  if (button) {
    button.addEventListener('click', event => {
      if (event.button === 0) new Uploader();
    });
  }
  
  if (document.querySelector('#uploader_frame')) new Uploader();
});
