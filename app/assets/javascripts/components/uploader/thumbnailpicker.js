import { extendFunc } from '../../utils/misc';
import { Player } from '../videos/player';

export const ThumbPicker = extendFunc(Player, {
  constructor(el) {
    ThumbPicker.Super.constructor.call(this, el, true);
    this.timeInput = el.querySelector('input');
    this.controls.fullscreen.parentNode.removeChild(this.controls.fullscreen);
    this.controls.volume.parentNode.removeChild(this.controls.volume);
  },
  pause() {
    if (this.video) this.video.pause();
    return false;
  },
  createMediaElement() {
    let result = ThumbPicker.Super.createMediaElement.call(this);
    result.addEventListener('loadedmetadata', () => this.jump(0.5));
    return result;
  },
  play() {
    ThumbPicker.Super.play.call(this);
    this.pause();
  },
  track(time, duration) {
    ThumbPicker.Super.track.call(this, time, duration);
    this.timeInput.value = time;
  },
  load(d, isVideo) {
    ThumbPicker.Super.load.call(this, d, isVideo);
    this.volume(0, true);
  }
});
