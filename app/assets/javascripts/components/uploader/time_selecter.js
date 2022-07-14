import { extendFunc } from '../../utils/misc';
import { Player } from '../videos/player';

export const TimeSelecter = extendFunc(Player, function(el) {
  el.querySelector('.water-drop').remove();
  this.nonpersistent = true;
  Player.call(this, el, true);
  this.timeInput = el.querySelector('input');
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
  load(data, isVideo) {
    if (this.source) URL.revokeObjectURL(this.source);
    if (!data) return;
    this.source = URL.createObjectURL(data);
    this.__audioOnly = !isVideo;
    this.unload();
    this.play();
    this.volume(0, true);
  }
});
