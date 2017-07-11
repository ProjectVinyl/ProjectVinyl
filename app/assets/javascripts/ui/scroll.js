import { jSlim } from '../utils/jslim';
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
function scrollTo(me, container = document.documentElement) {
  const childOff = jSlim.offset(me);
  const containerOff = jSlim.offset(container);
  const viewX = container.clientWidth, viewY = container.clientHeight;
  const elementX = (childOff.left - containerOff.left) - (viewX / 2) + (me.offsetWidth / 2),
        elementY = (childOff.top - containerOff.top) - (viewY / 2) + (me.offsetHeight / 2);

  animateScroll(elementX, elementY, container, 250);
}

jSlim.ready(function() {
  jSlim.all('.scroll-container', function(el) {
    var target = el.querySelector('.scroll-focus');
    if (target) {
      scrollTo(target, el);
    }
    if (el.dataset.documentScrollY) {
      document.documentElement.scrollTop = parseInt(el.dataset.documentScrollY, 10);
    }
    if (el.dataset.documentScrollX) {
      document.documentElement.scrollLeft = parseInt(el.dataset.documentScrollX, 10);
    }
  });
});

export { scrollTo };
