import { ajax } from '../utils/ajax';
import { all } from '../jslim/dom';
import { addDelegatedEvent } from '../jslim/events';

export function slideOut(holder) {
  recomputeHeight(holder);
  holder.classList.toggle('shown');
  all('.slideout.shown', el => el.classList.toggle('shown', el == holder));
  return holder;
}

export function recomputeHeight(holder) {
  const h = holder.querySelector('.group.active').offsetHeight;
  holder.style.minHeight = `${h}px`;
  holder.style.maxHeight = `${h + 10}px`;
}

addDelegatedEvent(document, 'click', '.slider-toggle:not(.loading)', (e, target) => {
  if (e.button !== 0) return;
  e.preventDefault();
  
  const holder = document.querySelector(target.dataset.target);
  
  if (target.classList.contains('loadable')) {
    target.classList.add('loading');
    ajax.get(target.dataset.url).json(json => {
      target.classList.remove('loading');
      target.classList.remove('loadable');
      holder.innerHTML = json.content;
      slideOut(holder);
    });
    return;
  }
  
  slideOut(holder);
});
