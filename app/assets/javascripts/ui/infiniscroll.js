import { jSlim } from '../utils/jslim.js';

function initInfinitePage(target) {
  var path = target.dataset.path;
  var startFrom = target.dataset.ref;
  var endWith = target.dataset.startRef;
  
  var loadingBefore = false;
  var loadingAfter = false;
  
  window.addEventListener('scroll', updateInfinitePage);
  
  function updateInfinitePage() {
    if (endWith && document.scrollingElement.scrollTop == 0) {
      if (!loadingBefore) {
        loadingBefore = true;
        target.classList.add('loading-before');
        ajax.get(path + '&end=' + endWith).json(function(json) {
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
    if(document.scrollingElement.scrollTop + window.innerHeight == document.body.offsetHeight) {
      if (!loadingAfter) {
        loadingAfter = true;
        target.addClass('loading-after');
        ajax.get(path + '&start=' + startFrom).json(function(json) {
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