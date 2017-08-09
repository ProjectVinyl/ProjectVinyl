import { extendFunc } from '../utils/misc';
import { Player } from './videos';

export const ThumbPicker = extendFunc(Player, {
  constructor: function(el) {
    ThumbPicker.Super.constructor.call(this, el, true);
    this.timeInput = el.querySelector('input');
    this.controls.fullscreen.parentNode.removeChild(this.controls.fullscreen);
    this.controls.volume.parentNode.removeChild(this.controls.volume);
  },
  pause: function() {
    if (this.video) this.video.pause();
    return false;
  },
  createMediaElement: function() {
    let result = ThumbPicker.Super.createMediaElement.call(this);
    result.addEventListener('loadedmetadata', () => this.jump(0.5));
    return result;
  },
  play: function() {
    ThumbPicker.Super.play.call(this);
    this.pause();
  },
  track: function(time, duration) {
    ThumbPicker.Super.track.call(this, time, duration);
    this.timeInput.value = time;
  },
  load: function(d, isVideo) {
    ThumbPicker.Super.load.call(this, d, isVideo);
    this.volume(0, true);
  }
});
