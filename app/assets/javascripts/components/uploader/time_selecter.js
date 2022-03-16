import { extendFunc } from '../../utils/misc';
import { Player } from '../videos/player';

export const TimeSelecter = extendFunc(Player, {
  constructor(el) {
    this.nonpersistent = true;
    TimeSelecter.Super.constructor.call(this, el, true);
    this.timeInput = el.querySelector('input');
    this.controls.fullscreen.parentNode.removeChild(this.controls.fullscreen);
    this.controls.volume.parentNode.removeChild(this.controls.volume);
    this.contextmenu.setDisabled(true);
    this.waterdrop = null;
  },
  pause() {
    if (this.video) {
      this.video.pause();
    }
    return false;
  },
  createMediaElement() {
    let result = TimeSelecter.Super.createMediaElement.call(this);
    result.addEventListener('loadedmetadata', () => this.jump(0.5));
    return result;
  },
  play() {
    TimeSelecter.Super.play.call(this);
    this.pause();
  },
  track(time, duration) {
    TimeSelecter.Super.track.call(this, time, duration);
    this.timeInput.value = time;
    this.timeInput.dispatchEvent(new CustomEvent('change', {
      bubbles: true, cancelable: true
    }));
  },
  load(d, isVideo) {
    TimeSelecter.Super.load.call(this, d, isVideo);
    this.volume(0, true);
  }
});
