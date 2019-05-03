import { getTagEditor } from './tageditor';
import { ThumbPicker } from './thumbnailpicker';
import { resizeFont } from '../ui/resize';
import { focusTab } from '../ui/tabset';
import { extendObj } from '../utils/misc';
import { canPlayType } from '../utils/videos';
import { all, nodeFromHTML } from '../jslim/dom';
import { ready } from '../jslim/events';
import { Validator } from './validator';
import { UploadQueue } from './uploadqueue';
import { setupEditable } from '../ui/editable';

const INSTANCES = [];
let uploadingQueue = null;

function tabMarkup(id) {
  return document.getElementById('tab-template').innerHTML.replace(/\{index\}/g, id || '').replace(/\{id\}/g, id);
}

function uploaderMarkup(id) {
  return document.getElementById('template').innerHTML.replace(/\{id\}/g, id);
}

function cleanup(title) {
  // 1. Convert everything to lowercase
  // 2. Remove any beginning digit strings
  // 3. Replace non-alpha/non-whitespace with a single space
  // 4. Convert first letters to uppercase
  // 5. Strip whitespace
  return title.toLowerCase().replace(/^[0-9]*/g, '').replace(/[-_]|[^a-z\s]/gi, ' ').replace(/(^|\s)[a-z]/g, i => i.toUpperCase()).trim();
}

function Uploader() {
  this.id = INSTANCES.length;
  
  // Create new upload form from template
  this.el = nodeFromHTML(uploaderMarkup(this.id));
  this.tab = nodeFromHTML(tabMarkup(this.id));
  
  // Deselect prior tab and insert
  const selectedTab = document.querySelector('#uploader_frame > .tab.selected');
  if (selectedTab) selectedTab.classList.remove('selected');
  
  document.getElementById('uploader_frame').appendChild(this.el);
  document.getElementById('new_tab_button').insertAdjacentElement('beforebegin', this.tab);
  
  this.tab.label = this.tab.querySelector('.label');
  this.tab.progress = this.tab.querySelector('.progress');
  this.tab.progress.fill = this.tab.progress.querySelector('.fill');
  
  this.form = this.el.querySelector('form');
  
  this.video = this.el.querySelector('#video-upload');
  this.videoTitle = this.el.querySelector('#video_title input');
  this.title = this.el.querySelector('#video_title .content');
  
  this.thumbPick = this.el.querySelector(`li[data-target="thumbpick_${this.id}"]`);
  this.thumbUpload = this.el.querySelector(`li[data-target="thumbupload_${this.id}"]`);
  
  this.tagEditor = getTagEditor(this.el.querySelector('.tag-editor'));
  
  this.source = this.el.querySelector('#video_source');
  this.srcNeeded = true;
  
  all(this.el, '.editable', setupEditable);
  
  // FIXME
  requestAnimationFrame(() => this.tab.classList.remove('hidden'));
  
  // Close button click
  this.tab.querySelector('i').addEventListener('click', () => this.dispose());
  this.form.addEventListener('submit', event => {
    if (!uploadingQueue) uploadingQueue = new UploadQueue();
    uploadingQueue.enqueue(this);
    event.preventDefault();
  });
  
  const newVideo = this.el.querySelector('#new_video');
  
  newVideo.addEventListener('tagschange', () => {
    this.validateInput();
  });
  
  newVideo.addEventListener('change', event => {
    if (!event.target.matches('h1#video_title input')) return;
    this.validateInput();
  });
  
  const thumbPicker = this.el.querySelector(`.tab[data-tab="thumbpick_${this.id}"]`);
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
  initPlayer() {
    this.player = new ThumbPicker();
    this.player.constructor(this.el.querySelector('.video'));
  },
  showUI(file) {
    all(this.el, '.ui.hidden, .ui.shown', e => {
      e.classList.toggle('hidden');
      e.classList.remove('shown');
    });
    
    const title = cleanup(file.title);
    this.title.innerText = title;
    this.videoTitle.value = title;
    this.tab.label.innerText = `${file.title}.${file.type}`;
  },
  accept(file) {
    this.hasFile = true;
    
    if (this.video.classList.contains('shown')) this.showUI(file);
    if (!this.player) this.initPlayer();
    
    if (this.needsCover) {
      this.player.load(null);
      this.thumbUpload.click();
      this.thumbPick.dataset.disabled = 1;
    } else {
      if (canPlayType(file.mime)) {
        this.player.load(file.data, true);
        this.thumbPick.removeAttribute('data-disabled');
        this.thumbPick.click();
      } else {
        this.thumbUpload.click();
        this.thumbPick.dataset.disabled = 1;
      }
    }
    
    this.validateInput();
  },
  validateInput() {
    const title = this.videoTitle.value;
    this.ready = false;
    
    if (!title) return this.notify('You need to provide a title.');
    if (this.needsCover && !this.hasCover) return this.notify('Audio files require a cover image.');
    
    const tags = this.tagEditor.tags.baked();
    
    if (!this.source.value) {
      this.srcNeeded = tags.indexOf('source needed') !== -1;
      
      if (!this.srcNeeded) {
        this.info('You have not provided a source. If you know what it is add it to the source field, otherwise consider tagging this video as \'source needed\' so others know to search for one.');
      } else {
        this.el.info.classList.add('hidden');
      }
    } else {
      this.el.info.classList.add('hidden');
    }
    
    if (tags.length === 0) return this.notify('You need at least one tag.');
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
      const otherTab = this.tab.parentNode.querySelector(`li.button:not([data-disabled]):not(.hidden)[data-target]:not([data-target="${this.id}"])`);
      if (otherTab) focusTab(otherTab);
    }
    
    if (ref) {
      this.el.innerHTML = `Uploading Complete. You can see your new video over <a target="_blank" href="${ref}">here</a>.`;
    }
  },
  error() {
    this.tab.classList.add('error');
  },
  dispose() {
    INSTANCES.splice(INSTANCES.indexOf(this), 1);

    if (!INSTANCES.length) {
      setTimeout(() => new Uploader(), 100);
    }
  }
}, Validator.prototype);

ready(() => {
  if (!document.querySelector('#uploader_frame')) return;
  
  document.getElementById('new_tab_button').addEventListener('click', event => {
    if (event.button === 0) new Uploader();
  });
  
  new Uploader();
});
