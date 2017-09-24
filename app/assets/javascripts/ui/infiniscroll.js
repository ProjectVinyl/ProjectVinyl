import { ready } from '../jslim/events';
import { ajax } from '../utils/ajax';

function throttleFunc(func, ms) {
  let scheduled = null;
  return () => {
    if (!scheduled) scheduled = setTimeout(() => {
      func();
      scheduled = null;
    }, ms);
  };
}

function scrollListener(target, ref, position, test, data) {
  const path = target.dataset.url + '/page';
  let busy = false;
  return () => {
    if (busy || !test()) return false;
    busy = true;
    target.classList.add('loading-' + position);
    ajax.get(path, {
      path: target.dataset.path, end: target.dataset.startRef, start: target.dataset.ref, position: position
    }).json(json => {
      if (json.content) {
        if (json.start) target.dataset.startRef = json.start;
        if (json.end) target.dataset.ref = json.end;
        ref.insertAdjacentHTML(position + 'end', json.content);
      }
      busy = false;
      target.classList.remove('loading-' + position);
    });
    return true;
  };
}

ready(() => {
  const target = document.querySelector('.infinite-page');
  if (!target) return;
  const context = target.closest('.context-3d') || document.scrollingElement;
  const top = scrollListener(target, target.querySelector('.row.header'), 'before', () => context.scrollTop == 0);
  const bottom = scrollListener(target, target, 'after', () => (context.scrollTop + context.offsetHeight) >= context.scrollHeight);
  
  context.addEventListener('scroll', throttleFunc(() => {
    if (!top()) {
      bottom();
    }
  }, 200));
});
