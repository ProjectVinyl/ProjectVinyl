import { addDelegatedEvent, bindAll, halt, bindEvent } from '../../jslim/events';
import { Key, isNumberKey, getNumberKeyValue } from '../../utils/key';
import { triggerDrop } from './waterdrop';
import { fullscreenPlayer } from './fullscreen';
import { navTo } from './playlist_actions';

export function registerEvents(player, el) {
  let tapped = false;
  let activeTouches = [];

  function onTouchEvent(ev) {
    activeTouches = activeTouches.filter(t => t.identifier !== ev.identifier)
  }

  bindAll(el, {
    click: ev => {
      if (ev.button !== 0) {
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

          triggerDrop(player.waterdrop, player.togglePlayback() ? 'pause' : 'play');
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

function bindGestures(player) {
  addDelegatedEvent(document, 'click', 'a[data-time]', (ev, target) => {
    if (ev.button !== 0) return;
    player.skipTo(parseFloat(target.dataset.time));
  });
  bindEvent(document, 'keydown', ev => {
    if (player.video && !document.querySelector('input:focus, textarea:focus')) {
      const oldVolume = player.getVolume();

      if (ev.key == 'MediaPlayPause' || ev.keyCode === Key.SPACE) {
        triggerDrop(player.waterdrop, player.togglePlayback() ? 'pause' : 'play');
        return halt(ev);
      } else if (ev.key == 'MediaTrackPrevious' || ev.keyCode == Key.LEFT) {
        player.skip(-5);
        triggerDrop(player.waterdrop, 'backward');
        return halt(ev);
      } else if (ev.key == 'MediaTrackNext' || ev.keyCode == Key.RIGHT) {
        player.skip(5);
        triggerDrop(player.waterdrop, 'forward');
        return halt(ev);
      } else if (ev.keyCode == Key.UP) {
        player.skip(0, 0.1);
        if (player.getVolume() != oldVolume) {
          triggerDrop(player.waterdrop, 'volume-up');
        }
        return halt(ev);
      } else if (ev.keyCode == Key.DOWN) {
        player.skip(0, -0.1);
        if (player.getVolume() != oldVolume) {
          triggerDrop(player.waterdrop, player.getVolume() == 0 ? 'volume-off' : 'volume-down');
        }
        return halt(ev);
      } else if (ev.keyCode == Key.HOME) {
        player.jump(0);
        triggerDrop(player.waterdrop, 'fast-backward');
        return halt(ev);
      } else if (ev.keyCode == Key.END) {
        player.jump(0.99);
        triggerDrop(player.waterdrop, 'fast-forward');
        return halt(ev);
      } else if (isNumberKey(ev.keyCode)) {
        player.jump(getNumberKeyValue(ev.keyCode) / 10);
        return halt(ev);
      }
    }
  });
}
