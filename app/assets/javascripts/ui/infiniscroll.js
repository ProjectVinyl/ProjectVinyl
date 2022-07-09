import { ready } from '../jslim/events';
import { ajaxGet } from '../utils/ajax';
import { scrollContext } from './reflow';

export function throttleFunc(func, ms) {
  let scheduled = null;
  return () => {
    if (!scheduled) scheduled = setTimeout(() => {
      func();
      scheduled = null;
    }, ms);
  };
}

function scrollListener(target, ref, position, test, data) {
  const path = target.dataset.url + '.json';
  let blocked = false;
  return () => {
    if (blocked || !test()) {
      return false;
    }

    blocked = true;
    target.classList.add('loading-' + position);
    ajaxGet(path, {
      offset: 50,
      path: target.dataset.path,
      end: target.dataset.end,
      start: target.dataset.start,
      position: position
    }).json(json => {
      if (json.content) {
        if (json.start && position == 'after') {
          target.dataset.start = json.start;
        }

        if (json.end && position == 'before') {
          target.dataset.end = json.end;
        }

        ref.insertAdjacentHTML(position + 'end', json.content);
        blocked = false;
      }
      target.classList.remove('loading-' + position);
    });
    return true;
  };
}

ready(() => {
  const target = document.querySelector('.infinite-page');
  if (!target) return;
  const context = scrollContext(target);
  const top = scrollListener(target, target.querySelector('.row.header'), 'after', () => context.scrollTop == 0);
  const bottom = scrollListener(target, target, 'before', () => (context.scrollTop + context.offsetHeight) >= context.scrollHeight);
  
  context.addEventListener('scroll', throttleFunc(() => {
    (top() || bottom());
  }, 200));
});
