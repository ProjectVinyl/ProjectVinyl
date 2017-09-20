import { bindAll } from './jslim';

/* Standardise fullscreen API */
(p => {
  p.requestFullscreen = p.requestFullscreen || p.mozRequestFullScreen || p.msRequestFullscreen || p.webkitRequestFullscreen || function() {};
})(Element.prototype);
(d => {
  d.exitFullscreen = d.exitFullscreen || d.mozCancelFullScreen || d.msExitFullscreen || d.webkitExitFullscreen || function() {};
})(document);

export function isFullscreen() {
  return document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
}

export function onFullscreenChange(func) {
  bindAll(document, {
    webkitfullscreenchange: func,
    mozfullscreenchange: func,
    fullscreenchange: func
  });
}
