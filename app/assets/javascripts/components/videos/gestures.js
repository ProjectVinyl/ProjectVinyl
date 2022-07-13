import { addDelegatedEvent, bindAll, halt, bindEvent } from '../../jslim/events';
import { Key, isNumberKey, getNumberKeyValue } from '../../utils/key';
import { triggerDrop } from './waterdrop';
import { fullscreenPlayer } from './fullscreen';
import { navTo } from './playlist_actions';
import { touchSlider } from '../slider_transitive';

export function registerEvents(player, el) {
  let tapped = false;
  let activeTouches = [];

  function onTouchEvent(ev) {
    activeTouches = activeTouches.filter(t => t.identifier !== ev.identifier)
  }

  bindAll(el, {
    click: ev => {
      if (ev.button !== 0 || ev.defaultPrevented) {
        return;
      }

      if (!player.contextmenu.hide(ev)) {
        let target = ev.target.closest('.items a, #playlist_next:not(.disabled), #playlist_prev:not(.disabled)');
        if (target) {
          halt(ev);
          return navTo(player, target);
        }

        if (player.playlist && ev.target.closest('.playlist-toggle')) {
          return player.playlist.classList.toggle('visible');
        }

        if (ev.target.closest('.action, .voluming, .tracking')) {
          return;
        }

        if (player.dom.dataset.state != 'playing' || player.dom.toggler.interactable()) {
          if (player.playlist && player.playlist.classList.contains('visible')) {
            return player.playlist.classList.remove('visible');
          }

          const shouldTriggerDrop = player.dom.dataset.state != 'ready' && player.dom.dataset.state != 'stopped';
          const newState = player.togglePlayback() ? 'pause' : 'play';
          if (shouldTriggerDrop) {
            triggerDrop(player.dom.querySelector('.water-drop'), newState);
          }
        }
      }
    },
    touchstart: ev => {
      if (fullscreenPlayer === player && activeTouches.length) {
        return halt(ev);
      }

      if (!tapped) {
        tapped = setTimeout(() => tapped = null, 500);
        activeTouches.push({identifier: ev.identifier});

        return;
      }

      clearTimeout(tapped);
      tapped = null;
      player.fullscreen(!isFullscreen());

      halt(ev);
    },
    touchmove: onTouchEvent,
    touchend: onTouchEvent,
    touchcancel: onTouchEvent
  });

  bindGestures(player);
}

function adjustTime(player, time) {
  player.skipTo(player.getTime() + time);
  touchSlider(player.controls.track);
  triggerDrop(player.dom.querySelector('.water-drop'), time < 0 ? 'backward' : 'forward');
}

function adjustVolume(player, volume) {
  const oldVolume = player.getVolume();

  player.volume(player.getVolume() + volume, volume < 0 && player.isMuted());
  touchSlider(player.controls.volumeSlider.slider);
  if (player.getVolume() != oldVolume) {
    triggerDrop(player.dom.querySelector('.water-drop'), 'volume-up');
  }
}

function bindGestures(player) {
  const waterdrop = player.dom.querySelector('.water-drop');

  addDelegatedEvent(document, 'click', 'a[data-time]', (ev, target) => {
    if (ev.button !== 0) return;
    player.skipTo(parseFloat(target.dataset.time));
  });
  bindEvent(document, 'keydown', ev => {
    if (player.video && !document.querySelector('input:focus, textarea:focus')) {
      if (ev.key == 'MediaPlayPause' || ev.keyCode === Key.SPACE) {
        triggerDrop(waterdrop, player.togglePlayback() ? 'pause' : 'play');
        return halt(ev);
      } else if (ev.key == 'MediaTrackPrevious' || ev.keyCode == Key.LEFT) {
        adjustTime(player, -5);
        return halt(ev);
      } else if (ev.key == 'MediaTrackNext' || ev.keyCode == Key.RIGHT) {
        adjustTime(player, 5);
        return halt(ev);
      } else if (ev.keyCode == Key.UP) {
        adjustVolume(player, 0.1);
        return halt(ev);
      } else if (ev.keyCode == Key.M) {
        player.volume(player.getVolume(), !player.isMuted());
        triggerDrop(waterdrop, player.isMuted() ? 'volume-off' : 'volume-up');
        return halt(ev);
      } else if (ev.keyCode == Key.DOWN) {
        adjustVolume(player, -0.1);
        return halt(ev);
      } else if (ev.keyCode == Key.HOME) {
        player.jump(0);
        triggerDrop(waterdrop, 'fast-backward');
        return halt(ev);
      } else if (ev.keyCode == Key.END) {
        player.jump(0.99);
        triggerDrop(waterdrop, 'fast-forward');
        return halt(ev);
      } else if (isNumberKey(ev.keyCode)) {
        player.jump(getNumberKeyValue(ev.keyCode) / 10);
        return halt(ev);
      }
    }
  });
}
