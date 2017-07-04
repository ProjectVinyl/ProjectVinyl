import { jSlim } from '../utils/jslim';

function animateScroll(elementX, elementY, viewport, duration) {
  const startingX = viewport.scrollLeft;
  const startingY = viewport.scrollTop;
  const diffX = elementX - startingX;
  const diffY = elementY - startingY;
  let start;

  requestAnimationFrame(function step(timestamp) {
    if (!start) start = timestamp;
    const time = timestamp - start;
    // 0.5*(1-cosx) is the easing function used here,
    // linear would be simply be Math.min(time / duration, 1)
    const percent = (1 - Math.cos(Math.min(time / duration, 1) * Math.PI)) / 2;
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
  const elementX = (childOff.left - containerOff.left) - (viewX / 2),
        elementY = (childOff.top - containerOff.top) - (viewY / 2);

  animateScroll(elementX, elementY, container, 500);

  return me;
}

// app/views/video/view.html.erb
window.scrollTo = scrollTo;

export { scrollTo };
