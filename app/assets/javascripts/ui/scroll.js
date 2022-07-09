import { offset, subtractOffsets } from '../jslim/dom';
import { ready } from '../jslim/events';
import { ease } from '../utils/math';

function animateScroll(diff, viewport, duration) {
  const startingX = viewport.scrollLeft;
  const startingY = viewport.scrollTop;
  let start;
  
  requestAnimationFrame(function step(timestamp) {
    if (!start) start = timestamp;
    const time = timestamp - start;
    const percent = ease(Math.min(time / duration, 1));
    
    viewport.scrollLeft = startingX + diff.left * percent;
    viewport.scrollTop = startingY + diff.top * percent;
    
    if (time < duration) requestAnimationFrame(step);
  });
}

// me: The element you want to find
// container: The container whose scroll position changes
export function scrollTo(me, container) {
  container = container || me.closest('.context-3d') || document.documentElement;
  
  animateScroll(subtractOffsets(subtractOffsets(offset(me), offset(container)), {
    left: (container.clientWidth - me.offsetWidth) / 2,
    top: (container.clientHeight - me.offsetHeight) / 2
  }), container, 250);
}

ready(() => document.querySelectorAll('.scroll-container').forEach(el => {
  const target = el.querySelector('.scroll-focus');
  if (target) scrollTo(target, el);
  if (el.dataset.documentScrollY) {
    document.documentElement.scrollTop = parseInt(el.dataset.documentScrollY, 10);
  }
  if (el.dataset.documentScrollX) {
    document.documentElement.scrollLeft = parseInt(el.dataset.documentScrollX, 10);
  }
}));
