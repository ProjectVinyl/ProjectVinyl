
/* Standardise fullscreen API */
(function(p) {
  p.requestFullscreen = p.requestFullscreen || p.mozRequestFullScreen || p.msRequestFullscreen || p.webkitRequestFullscreen || function() {};
  p.exitFullscreen = document.exitFullscreen || document.mozCancelFullScreen || document.msExitFullscreen || document.webkitExitFullscreen || function() {};
})(Element.prototype);
