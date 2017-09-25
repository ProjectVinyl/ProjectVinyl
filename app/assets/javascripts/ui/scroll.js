import { all, offset } from '../jslim/dom';
import { ready } from '../jslim/events';
import { ease } from '../utils/math';

function animateScroll(elementX, elementY, viewport, duration) {
  const startingX = viewport.scrollLeft;
  const startingY = viewport.scrollTop;
  const diffX = elementX - startingX;
  const diffY = elementY - startingY;
  let start;
  
  requestAnimationFrame(function step(timestamp) {
    if (!start) start = timestamp;
    const time = timestamp - start;
    const percent = ease(Math.min(time / duration, 1));
    
    viewport.scrollLeft = startingX + diffX * percent;
    viewport.scrollTop = startingY + diffY * percent;
    
    if (time < duration) requestAnimationFrame(step);
  });
}

// me: The element you want to find
// container: The container whose scroll position changes
export function scrollTo(me, container) {
  if (!container) {
    container = me.closest('.context-3d') || document.documentElement;
  }
  
  const childOff = offset(me);
  const containerOff = offset(container);
  
  var viewX = container.clientWidth / 2;
  var viewY = container.clientHeight / 2;
  
  const elementX = (childOff.left - containerOff.left) - viewX + (me.offsetWidth / 2);
  const elementY = (childOff.top - containerOff.top) - viewY + (me.offsetHeight / 2);
  
  animateScroll(container.scrollLeft + elementX, container.scrollTop + elementY, container, 250);
}

ready(() => all('.scroll-container', el => {
  const target = el.querySelector('.scroll-focus');
  if (target) scrollTo(target, el);
  if (el.dataset.documentScrollY) {
    document.documentElement.scrollTop = parseInt(el.dataset.documentScrollY, 10);
  }
  if (el.dataset.documentScrollX) {
    document.documentElement.scrollLeft = parseInt(el.dataset.documentScrollX, 10);
  }
}));
