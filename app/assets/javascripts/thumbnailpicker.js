function ThumbPicker() { }
Player.Extend(ThumbPicker, {
  constructor: function(el) {
    ThumbPicker.Super.constructor.call(this, el, true);
    this.time_input = el.find('input');
    el.find('.icon.fullscreen, .icon.volume').remove();
  },
  pause: function() {
    if (this.video) this.video.pause();
    return false;
  },
  start: function() {
    if (!this.video) {
      ThumbPicker.Super.start.call(this);
      if (this.video) {
        var me = this;
        this.video.addEventListener('loadedmetadata', function() {
          me.changetrack(0.5);
        });
      }
    } else {
      ThumbPicker.Super.start.call(this);
    }
    this.pause();
  },
  changetrack: function(progress) {
    ThumbPicker.Super.changetrack.call(this, progress);
    this.time_input.val(this.video.currentTime);
  },
  load: function(d) {
    this.start();
    this.volume(0, !0);
    ThumbPicker.Super.load.call(this, d);
    this.start();
  }
});