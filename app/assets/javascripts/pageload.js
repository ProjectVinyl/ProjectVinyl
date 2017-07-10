import { ajax } from './utils/ajax';
import { jSlim } from './utils/jslim';

jSlim.ready(function() {
  var banner = document.getElementById('banner');
  if (!banner) return;
  
  if (window.requestAnimationFrame) {
    return animator();
  }
  
  console.log('RequestAnimationFrame not supported. Using scroll instead');
  window.addEventListener('scroll', scroller);
  
  function animator() {
    scroller();
    window.requestAnimationFrame(animator);
  }
  
  function scroller() {
    var top = window.scrollY;
    var width = window.innerWidth;
    if (top <= 200) banner.style.backgroundPosition = 'top calc(50% + ' + (top * 0.5) + 'px) ' + (width > 1300 ? 'left' : 'center') + ', top calc(50% + ' + (top * 0.5) + 'px) right';
  }
});
