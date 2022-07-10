/*
 * Fullscreen events for the video player
 */
import { isFullscreen, onFullscreenChange } from '../../utils/fullscreen';

export let fullscreenPlayer = null;

export function setFullscreen(player) {
  if (fullscreenPlayer) {
    fullscreenPlayer.fullscreenChanged(false);
  }

  fullscreenPlayer = player;

  if (fullscreenPlayer) {
    fullscreenPlayer.fullscreenChanged(true);
    player.dom.requestFullscreen();
  } else if (isFullscreen()) {
    document.exitFullscreen();
  }
}

onFullscreenChange(() => {
  if (fullscreenPlayer) {
    fullscreenPlayer.fullscreenChanged(isFullscreen());
  }
});
