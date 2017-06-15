function ThumbPicker() { }
Player.Extend(ThumbPicker, {
  constructor(el) {
    ThumbPicker.Super.constructor.call(this, el, true);
    this.time_input = el.find('input');
    el.find('.icon.fullscreen, .icon.volume').remove();
  },
  pause() {
    if (this.video) this.video.pause();
    return false;
  },
  start() {
    if (!this.video) {
      ThumbPicker.Super.start.call(this);
      if (this.video) {
        const me = this;
        this.video.addEventListener('loadedmetadata', () => {
          me.changetrack(0.5);
        });
      }
    } else {
      ThumbPicker.Super.start.call(this);
    }
    this.pause();
  },
  changetrack(progress) {
    ThumbPicker.Super.changetrack.call(this, progress);
    this.time_input.val(this.video.currentTime);
  },
  load(d) {
    this.start();
    this.volume(0, !0);
    ThumbPicker.Super.load.call(this, d);
    this.start();
  }
});
