/*
 * Fullscreen events for the video player
 */
import { isFullscreen, onFullscreenChange } from '../../utils/fullscreen';

let fadeControl = null;

export let fullscreenPlayer = null;

function fadeOut() {
  cancelFade();
  fadeControl = setTimeout(() => {
    if (fullscreenPlayer) {
      fullscreenPlayer.controls.hide();
    }
    fadeControl = null;
  }, 1000);
}

function cancelFade(stop) {
  if (stop) document.removeEventListener('mousemove', fadeOut);
  if (fullscreenPlayer) fullscreenPlayer.controls.show();
  if (fadeControl) fadeControl = clearTimeout(fadeControl);
}

export function setFullscreen(player) {
  cancelFade(true);

  if (fullscreenPlayer) {
    fullscreenPlayer.fullscreenChanged(false);
  }

  fullscreenPlayer = player;

  if (fullscreenPlayer) {
    fullscreenPlayer.fullscreenChanged(true);
    document.addEventListener('mousemove', fadeOut);
    fadeOut();
    player.dom.requestFullscreen();
  } else if (isFullscreen()) {
    document.exitFullscreen();
  }
}

onFullscreenChange(() => {
  const fullscreen = isFullscreen()
  if (!fullscreen) {
    cancelFade(true);
  }
  if (fullscreenPlayer) {
    fullscreenPlayer.fullscreenChanged(fullscreen);
  }
});
