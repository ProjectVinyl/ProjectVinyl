import { toBool } from '../utils/misc';

export function Validator(el) {
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
  
  const changeVideo = this.el.querySelector('.change-video');
  if (changeVideo) {
    changeVideo.addEventListener('click', () => {
      this.video.input.click();
    });
  }
  
  this.video.input.addEventListener('change', () => {
    const file = this.video.input.files[0];
    const title = file.name.split('.');
    
    this.needsCover = !!file.type.match(/audio\//);
    this.accept({
      title: title.splice(0, title.length - 1).join('.'),
      mime: file.type,
      type: title[title.length - 1],
      data: file
    });
  });
  
  this.cover.input.addEventListener('change', () => {
    this.hasCover = true;
    this.validateInput();
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
