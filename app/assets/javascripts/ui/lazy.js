import { ajax } from '../utils/ajax.js';
import { jSlim } from '../utils/jslim.js';

function lazyLoad(button) {
  var target = document.getElementById(button.dataset.target);
  var page = parseInt(button.dataset.page) + 1;
  button.classList.add('working');
  ajax.get(button.dataset.url, {
    page: page,
    id: button.dataset.id
  }).json(function(json) {
    button.classList.remove('working');
    if (json.page == page) {
      target.innerHTML += json.content;
      button.dataset.page = page;
    } else {
      button.parentNode.removeChild(button);
    }
  });
}

jSlim.on(document, 'click', '.load-more button', function() {
  lazyLoad(this);
});

jSlim.on(document, 'click', '.mix a', function(e) {
  document.location.replace(this.href + '&t=' + document.querySelector('#video .player').getPlayerObj().video.currentTime);
  e.preventDefault();
});
