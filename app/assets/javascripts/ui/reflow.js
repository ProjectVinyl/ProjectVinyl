/*
 * Correct page scrolling after content change
 */

export function scrollContext() {
  return document.querySelector('.context-3d') || document.scrollingElement;
}

export function reflowElement(context) {
  let top = context.scrollTop;
  let left = context.sctollLeft;
  
  context.scrollTop = context.scrollLeft = 0;
  
  requestAnimationFrame(() => {
    context.scrollTop = Math.min(top, context.scrollHeight);
    context.scrollLeft = Math.min(left, context.scrollWidth);
  });
}

document.addEventListener('ajax:complete', () => {
  reflowElement(scrollContext());
});