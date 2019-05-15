import { toBool } from '../../utils/misc';

export function Validator(el) {
  this.el = el;
  
  this.hasCover = false;
  this.needsCover = toBool(el.dataset.needsCover);
  
  this.el.notify = this.el.querySelector('.notify');
  this.el.notify.bobber = this.el.notify.querySelector('.bobber');
  this.el.info = this.el.querySelector('.info');
  
  this.time = this.el.querySelector('#time');
  this.lastTime = -1;
  
  this.coverInput = this.el.querySelector('#cover-upload input[type=file]');
  this.videoInput = this.el.querySelector('#video-upload input[type=file]');
  
  const changeVideo = this.el.querySelector('.change-video');
  if (changeVideo) {
    changeVideo.addEventListener('click', () => {
      this.videoInput.click();
    });
  }
  
  this.videoInput.addEventListener('change', () => {
    const file = this.videoInput.files[0];
    const title = file.name.split('.');
    
    this.needsCover = !!file.type.match(/audio\//);
    this.accept({
      title: title.splice(0, title.length - 1).join('.'),
      mime: file.type,
      type: title[title.length - 1],
      data: file
    });
  });
  
  this.coverInput.addEventListener('change', () => {
    this.hasCover = true;
    this.validateInput();
  });
}
Validator.prototype = {
  isReady() {
    return this.hasFile && (this.hasCover || !this.needsCover) && this.ready;
  },
  notify(msg) {
    this.el.notify.classList.add('shown');
    this.el.notify.bobber.innerText = msg;
  },
  info(msg) {
    this.el.info.classList.remove('hidden');
    this.el.info.innerText = msg;
  }
};
