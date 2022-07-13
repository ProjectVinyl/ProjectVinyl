import { extendFunc } from '../../utils/misc';
import { Player } from '../videos/player';

export const TimeSelecter = extendFunc(Player, function(el) {
  this.nonpersistent = true;
  Player.call(this, el, true);
  this.timeInput = el.querySelector('input');
  this.contextmenu.setDisabled(true);
  this.waterdrop = null;
  this.volume(0, true);
}, {
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
    this.volume(0, true);
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
