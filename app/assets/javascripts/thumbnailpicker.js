import { Player } from './videos.js';

function ThumbPicker() {
}

Player.Extend(ThumbPicker, {
  constructor: function(el) {
    ThumbPicker.Super.constructor.call(this, el, true);
    this.timeInput = el.find('input');
    el.find('.icon.fullscreen, .icon.volume').remove();
  },
  pause: function() {
    if (this.video) this.video.pause();
    return false;
  },
  start: function() {
    var self = this;
    if (!this.video) {
      ThumbPicker.Super.start.call(this);
      if (this.video) {
        this.video.addEventListener('loadedmetadata', function() {
          self.changetrack(0.5);
        });
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
