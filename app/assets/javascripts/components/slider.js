/*
 * Enables functionality for a draggable slider control.
 */
import { addDelegatedEvent, dispatchEvent } from '../jslim/events';
import { clampPercentage } from '../utils/math';

function grabSlider(event, target) {
  function toggleBinding(mode) {
    ['mouseup', 'touchend', 'touchcancel'].forEach(t => document[mode + 'EventListener'](t, ender));
    ['mousemove', 'touchmove' ].forEach(t => document[mode + 'EventListener'](t, changer));
  }

  target = target.closest('.slider-control');
  dispatchEvent('slider:grab', getPercentage(target, event), target);
  target.classList.add('interacting');

  const changer = ev => jumpSlider(ev, target);
  const ender = ev => {
    target.classList.remove('interacting');
    toggleBinding('remove');
    dispatchEvent('slider:release', getPercentage(target, ev), target);
  };
  toggleBinding('add');
}

function jumpSlider(event, target) {
  target = target.closest('.slider-control');
  dispatchEvent('slider:jump', getPercentage(target, event), target);
}

export function getPercentage(el, ev) {
  const rect = el.getBoundingClientRect();
  const touch = (ev.touches || [])[0] || {pageX: 0, pageY: 0};
  return {
    x: clampPercentage((ev.pageX || touch.pageX || 0) - rect.left - window.pageXOffset, el.clientWidth),
    y: clampPercentage(el.clientHeight - ((ev.pageY || touch.pageY || 0) - rect.top - window.pageYOffset), el.clientHeight)
  };
}

addDelegatedEvent(document, 'click', '.slider-control', jumpSlider);
addDelegatedEvent(document, 'mousedown', '.slider-control .bob', grabSlider);
addDelegatedEvent(document, 'touchstart', '.slider-control .bob', grabSlider);
