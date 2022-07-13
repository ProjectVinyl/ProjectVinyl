import { addDelegatedEvent } from '../../../jslim/events';
import { TapToggler } from '../../taptoggle';

function getVolumeIcon(level) {
  if (level <= 0) return 'off';
  if (level < 0.33) return 'down';
  if (level < 0.66) return 'mid';
  return 'up';
}

export function initVolumeSlider(player, dom) {
  const slider = dom.querySelector('.volume');
  slider.indicator = dom.querySelector('.volume .indicator i');
  new TapToggler(slider);

  addDelegatedEvent(dom, 'slider:grab', '.volume .slider', ev => {
    if (!player.contextmenu.hide(ev)) {
      player.dom.classList.add('voluming');
    }
  });
  addDelegatedEvent(dom, 'slider:release', '.volume .slider', ev => {
    player.dom.classList.remove('voluming');
  });
  addDelegatedEvent(dom, 'slider:jump', '.volume .slider', ev => {
    if (!player.contextmenu.hide(ev)) {
      if (ev.detail.data.y >= 0) {
        player.volume(ev.detail.data.y);
      }
    }
  });

  addDelegatedEvent(dom, 'click', '.volume', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      if (slider.toggler.interactable()) {
        player.volume(player.__volume, !player.__muted);
      }
    }
  });

  return {
    slider: dom.querySelector('.volume .slider'),
    repaint(volume) {
      slider.indicator.setAttribute('class', 'fa fa-volume-' + getVolumeIcon(volume));
      slider.style.setProperty('--volume-level', volume);
    }
  };
}
