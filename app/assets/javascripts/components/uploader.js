import { uploadForm } from '../utils/progressform';
import { BBC } from '../utils/bbcode';
import { TagEditor } from './tageditor';
import { ThumbPicker } from './thumbnailpicker';
import { resizeFont } from '../ui/resize';
import { focusTab } from '../ui/tabset';
import { toBool, extendObj } from '../utils/misc';
import { Player } from './videos';
import { jSlim } from '../utils/jslim';

const INSTANCES = [];
let INDEX = 0;

const uploadingQueue = {
  running: false,
  items: [],
  enqueue: function(me) {
    if (me.isReady()) {
      this.items.push(me);
      return this.poke();
    }
  },
  enqueueAll: function(args) {
    this.items.push.apply(this.items, args);
    return this.poke();
  },
  poke: function() {
    if (this.running) return;
    this.running = true;
    var self = this;
    return this.tick(function() {
      let i = 0;
      while (self.items.length > 0 && !(i = self.items.shift()).isReady());
      if (i && i.isReady()) return i;
    });
  },
  tick: function(next) {
    const uploader = next();
    this.running = !!uploader;
    var self = this;
    if (this.running) {
      uploader.tab.classList.add('loading');
      uploader.tab.classList.add('waiting');
      uploadForm(uploader.form, {
        success: function(data) {
          uploader.complete(data.ref);
          if (next) next = self.tick(next);
        },
        error: function(message, error) {
          uploader.error();
          message.text(error);
        },
        progress: function(message, fill, percentage) {
          uploader.update(percentage);
          if (next && percentage > 100) next = self.tick(next);
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
  
  var self = this;
  
  var changeVideo = this.el.querySelector('.change-video');
  if (changeVideo) {
    changeVideo.addEventListener('click', function() {
      self.video.input.click();
    });
  }
  
  this.video.input.addEventListener('change', function(e) {
    self.needsCover = !!this.video.files[0].mime.match(/audio\//);
    self.accept(e.detail);
  });
  
  this.cover.input.addEventListener('change', function() {
    self.hasCover = true;
    self.validateInput();
  });
}
Validator.prototype = {
  isReady: function() {
    return this.hasFile && (this.hasCover || !this.needsCover) && this.ready;
  },
  notify: function(msg) {
    this.el.notify.classList.add('shown');
    this.el.notify.bobber.textContent = msg;
  },
  info: function(msg) {
    this.el.info.style.display = '';
    this.el.info.textContent = msg;
  }
};

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
  
  this.tab = document.querySelector('[data-target="new[' + this.id + ']"');
  
  this.tab.label = this.tab.querySelector('.label');
  this.tab.progress = this.tab.querySelector('.progress');
  this.tab.progress.fill = this.tab.progress.querySelector('.fill');
  
  this.form = this.el.querySelector('form');
  this.videoTitle = this.el.querySelector('#video_title');
  this.videoTitle.input = this.videoTitle.querySelector('input');
  this.videoDescription = this.el.querySelector('textarea.comment-content');
  this.title = this.videoTitle.querySelector('.content');
  
  this.tagEditor = TagEditor.getOrCreate(this.el.querySelector('.tag-editor'));
  
  this.source = this.el.querySelector('#video_source');
  this.srcNeeded = false;
  
  BBC.init(this.videoTitle);
  
  var self = this;
  
  // FIXME
  requestAnimationFrame(function() {
    self.tab.classList.remove('hidden');
  });
  
  // Close button click
  this.tab.querySelector('i').addEventListener('click', function() {
    self.dispose();
  });
  this.form.addEventListener('submit', function(event) {
    uploadingQueue.enqueue(self);
    event.preventDefault();
    event.stopImmediatePropagation();
  });

  const newVideo = this.el.querySelector('#new_video');
  const thumbPicker = this.el.querySelector('.tab[data-tab="thumbpick_' + this.id + '"]');

  newVideo.addEventListener('tagschange', function() {
    self.validateInput();
  });

  newVideo.addEventListener('change', function(event) {
    if (event.target.matches('h1#video_title input')) {
      self.validateInput();
    }
  });
  
  thumbPicker.addEventListener('tabblur', function() {
    self.lastTime = self.time.value;
    self.time.value = -1;
    self.validateInput();
  });
  
  thumbPicker.addEventListener('tabfocus', function() {
    self.time.value = self.lastTime;
    self.validateInput();
  });

  jSlim.all(this.el, 'h1.resize-target', function(t) {
    resizeFont(t);
  });
  
  Validator.call(this, this.el);
  focusTab(this.tab);
  
  INSTANCES.push(this);
}
Uploader.uploadAll = function() {
  uploadingQueue.enqueueAll(INSTANCES);
};
Uploader.prototype = extendObj({
  initPlayer: function() {
    this.player = new ThumbPicker();
    this.player.constructor(this.el.querySelector('.video'));
  },
  showUI: function(title) {
    jSlim.all(this.el, '.hidden', function(e) {
      e.classList.remove('hidden');
    });
    jSlim.all(this.el, '.shown', function(e) {
      e.classList.add('hidden');
      e.classList.remove('shown');
    });
    
    this.tab.label.textContent = title;
  },
  accept: function(file) {
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
      
      // FIXME: Polyfill Array.prototype.includes for IE
      // Why? -_-
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
      const otherTab = this.tab.parentNode.querySelector('li.button:not([data-disabled]):not(.hidden)[data-target]:not([data-target="' + this.id + '"])');
      if (otherTab) focusTab(otherTab);
    }
    
    if (ref) {
      this.el.innerHTML = 'Uploading Complete. You can see your new video over <a target="_blank" href="' + ref + '">here</a>.';
    }
  },
  error: function() {
    this.tab.classList.add('error');
  },
  dispose: function() {
    INSTANCES.splice(INSTANCES.indexOf(this), 1);
  }
}, Validator.prototype);

jSlim.ready(function() {
  const button = document.getElementById('new_tab_button');
  if (button) {
    button.addEventListener('click', function(event) {
      if (event.button === 0) {
        new Uploader();
      }
    });
  }
});

function UploadChecker(el) {
  Validator.call(this, el);
  if (this.needsCover) {
    this.initPlayer();
  }
}
UploadChecker.prototype = extendObj({
  initPlayer: function() {
    this.player = new ThumbPicker();
    this.player.constructor(this.el.querySelector('.video'));
    this.player.start();
  },
  accept: function(file) {
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
  validateInput: function() {
    if (this.needsCover && !this.hasCover) return this.notify('Audio files require a cover image.');
    this.el.notify.classList.remove('shown');
  }
}, Validator.prototype);

Uploader.createChecker = function(el) {
  return new UploadChecker(el);
};

jSlim.ready(function() {
  jSlim.all('#uploader_frame', function() {
    new Uploader();
  });
  jSlim.all('#video-editor', Uploader.createChecker);
});
