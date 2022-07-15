import { ajaxGet } from '../utils/ajax';
import { addDelegatedEvent } from '../jslim/events';

export function slideOut(holder, keepRest) {
  recomputeHeight(holder, () => {
    holder.classList.toggle('shown');
    document.querySelectorAll('.slideout.shown').forEach(el => {
      recomputeHeight(el, () => {
        if (!keepRest) {
          el.classList.toggle('shown', el == holder);
        }
      });
    });
  });
  return holder;
}

export function recomputeHeight(holder, continuation) {
  holder.classList.add('js-computing-height');
  requestAnimationFrame(() => {
    const h = holder.querySelector('.group.active').offsetHeight;
    holder.style.minHeight = `${h}px`;
    holder.style.maxHeight = `${h + 10}px`;
    if (continuation) continuation();
    setTimeout(() => {
      holder.classList.remove('js-computing-height');
    }, 500);
  });
}

addDelegatedEvent(document, 'click', '.slider-toggle:not(.loading)', (e, target) => {
  if (e.button !== 0) return;

  const holder = document.querySelector(target.dataset.target);
  const keepRest = e.ctrlKey;
  
  if (target.classList.contains('loadable')) {
    target.classList.add('loading');
    ajaxGet(target.dataset.url).json(json => {
      target.classList.remove('loading');
      target.classList.remove('loadable');
      holder.innerHTML = json.content;
      slideOut(holder, keepRest);
    });
    return;
  }
  
  slideOut(holder, keepRest);
});

addDelegatedEvent(document, 'toggle', '.slideout', (e, target) => recomputeHeight(target));
addDelegatedEvent(document, 'ajax:complete', '.slideout', (e, target) => recomputeHeight(target));
