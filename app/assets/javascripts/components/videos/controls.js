import { isFullscreen } from '../../utils/fullscreen';
import { addDelegatedEvent, bindEvent, halt } from '../../jslim/events';
import { initVolumeSlider } from './controls/volume_slider';
import { initTrackbar } from './controls/trackbar';

export function PlayerControls(player, dom) {
  this.dom = dom;
  this.player = player;

  this.fullscreen = dom.querySelector('.fullscreen .indicator');
  this.play = dom.querySelector('.play .indicator');

  this.volumeSlider = initVolumeSlider(player, dom);
  this.trackbar = initTrackbar(player, dom);

  addDelegatedEvent(dom, 'click', '.fullscreen', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      player.fullscreen(!isFullscreen());
      halt(ev);
    }
  });
  addDelegatedEvent(dom, 'click', '.maximise', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      player.maximise();
    }
  });
  addDelegatedEvent(dom, 'click', '.play', ev => {
    if (ev.button !== 0) return;
    player.togglePlayback();
  });
  bindEvent(dom, 'click', ev => {
    ev.preventDefault();
  });
}
PlayerControls.prototype = {
  hide() {
    this.player.dom.dataset.hideControls = '1';
  },
  show() {
    this.player.dom.dataset.hideControls = '0';
  }
};
