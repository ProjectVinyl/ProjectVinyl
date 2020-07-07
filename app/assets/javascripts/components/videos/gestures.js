import { bindEvent } from '../../jslim/events';
import { Key, isNumberKey, getNumberKeyValue } from '../../utils/key';
import { triggerDrop } from './waterdrop';

export function bindGestures(player) {
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