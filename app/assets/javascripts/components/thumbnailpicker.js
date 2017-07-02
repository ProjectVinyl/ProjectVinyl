import { Player } from './videos.js';

function ThumbPicker() {
}

Player.extend(ThumbPicker, {
  constructor: function(el) {
    ThumbPicker.Super.constructor.call(this, el, true);
    this.timeInput = el.querySelector('input');
    const fullscreen = el.querySelector('.icon.fullscreen');
    const volume = el.querySelector('.icon.volume');
    fullscreen.parentNode.removeChild(fullscreen);
    volume.parentNode.removeChild(volume);
  },
  pause: function() {
    if (this.video) this.video.pause();
    return false;
  },
  start: function() {
    if (!this.video) {
      ThumbPicker.Super.start.call(this);
      if (this.video) {
        this.video.addEventListener('loadedmetadata', () => this.changetrack(0.5));
      }
    } else {
      ThumbPicker.Super.start.call(this);
    }
    this.pause();
  },
  changetrack: function(progress) {
    ThumbPicker.Super.changetrack.call(this, progress);
    this.timeInput.val(this.video.currentTime);
  },
  load: function(d) {
    this.start();
    this.volume(0, !0);
    ThumbPicker.Super.load.call(this, d);
    this.start();
  }
});

export { ThumbPicker };
