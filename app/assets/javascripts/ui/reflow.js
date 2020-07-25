/*
 * Correct page scrolling after content change
 */
import { bindEvent } from '../jslim/events';

export function scrollContext(element) {
  if (element) {
    return element.closest('.context-3d') || document.scrollingElement;
  }
  return document.querySelector('.context-3d') || document.scrollingElement;
}

export function reflowElement(context) {
  requestAnimationFrame(() => {
    if (context.scrollTop > context.scrollHeight) {
      context.scrollTop = Math.min(context.scrollTop, context.scrollHeight);
    }
    if (context.scrollLeft > context.scrollWidth) {
      context.scrollLeft = Math.min(context.sctollLeft, context.scrollWidth);
    }
  });
}


bindEvent(document, 'ajax:complete', () => {
  reflowElement(scrollContext());
});
