import { jSlim } from '../utils/jslim';
import { ajax } from '../utils/ajax';

function throttledScroll(func) {
  var scheduled;
  return function() {
    if (!scheduled) scheduled = setTimeout(function() {
      func();
      scheduled = false;
    }, 200);
  }
}

function initInfinitePage(target) {
  var path = target.dataset.url + '/page';
  var startFrom = target.dataset.ref;
  var endWith = target.dataset.startRef;
  var scrollingContext = target.closest('.context-3d') || document.scrollingElement;
  
  var loadingBefore = false;
  var loadingAfter = false;
  
  scrollingContext.addEventListener('scroll', throttledScroll(updateInfinitePage));
  
  function updateInfinitePage() {
    if (endWith && scrollingContext.scrollTop == 0) {
      if (!loadingBefore) {
        loadingBefore = true;
        target.classList.add('loading-before');
        ajax.get(path, {
          path: target.dataset.path,
          end: endWith
        }).json(function(json) {
          if (json.start) {
            if (json.start== endWith) {
              endWith = null;
            } else {
              endWith = json.start;
            }
            loadingBefore = false;
          }
          target.querySelector('.row.header').insertAdjacentHTML('afterend', json.content);
          target.classList.remove('loading-before');
        });
      }
      return;
    }
    if (scrollingContext.scrollHeight - scrollingContext.scrollTop == scrollingContext.clientHeight) {
      if (!loadingAfter) {
        loadingAfter = true;
        target.classList.add('loading-after');
        ajax.get(path, {
          path: target.dataset.path,
          start: startFrom
        }).json(function(json) {
          if (json.content) {
            startFrom = json.end;
            target.insertAdjacentHTML('beforeend', json.content);
            loadingAfter = false;
          }
          target.classList.remove('loading-after');
        });
      }
    }
  }
}

jSlim.ready(function() {
  var target = document.querySelector('.infinite-page');
  if (target) {
    initInfinitePage(target);
  }
});
