import { ThumbPicker } from './thumbnailpicker';
import { extendObj } from '../utils/misc';
import { canPlayType } from '../utils/videos';
import { all } from '../jslim/dom';
import { ready } from '../jslim/events';
import { Validator } from './validator';

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
    if (canPlayType(file.mime)) {
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

ready(() => all('#video-editor', el => new UploadChecker(el)));
