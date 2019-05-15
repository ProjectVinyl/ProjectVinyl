/*
 * Fullscreen events for the video player
 */
import { isFullscreen, onFullscreenChange } from '../../utils/fullscreen';

let fadeControl = null;

export let fullscreenPlayer = null;

function fadeOut() {
  if (fullscreenPlayer) fullscreenPlayer.controls.show();
  if (fadeControl !== null) clearTimeout(fadeControl);
  fadeControl = setTimeout(() => {
    if (fullscreenPlayer) fullscreenPlayer.controls.hide();
    fadeControl = null;
  }, 1000);
}

function setFullscreen(sender) {
  fullscreenPlayer = sender;
  document.removeEventListener('mousemove', fadeOut);
  if (sender) {
    document.addEventListener('mousemove', fadeOut);
    fadeOut();
  }
}

onFullscreenChange(() => {
  if (fullscreenPlayer) fullscreenPlayer.fullscreen(isFullscreen());
});

