import { bindAll } from './jslim';

/* Standardise fullscreen API */
(function(p) {
  p.requestFullscreen = p.requestFullscreen || p.mozRequestFullScreen || p.msRequestFullscreen || p.webkitRequestFullscreen || function() {};
  p.exitFullscreen = document.exitFullscreen || document.mozCancelFullScreen || document.msExitFullscreen || document.webkitExitFullscreen || function() {};
})(Element.prototype);

export function isFullscreen() {
  return document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
}

export function onFullscreenChange(func) {
  bindAll(document, {
    webkitfullscreenchange: onFullscreen,
    mozfullscreenchange: onFullscreen,
    fullscreenchange: onFullscreen
  });
}
