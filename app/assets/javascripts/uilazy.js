import { ajax } from './ajax.js';

function lazyLoad(button) {
  var target = document.getElementById(button.dataset.target);
  var page = parseInt(button[0].dataset.page) + 1;
  button.classList.add('working');
  ajax.get(button.dataset.url, function(json) {
    button.classList.remove('working');
    if (json.page == page) {
      target.innerHTML += json.content;
      button.dataset.page = page;
    } else {
      $(button).remove();
    }
  }, {
    page: page,
    id: button.attr('data-id')
  });
}

$(document).on('click', '.load-more button', function() {
  lazyLoad(this);
});

$(document).on('click', '.mix a', function(e) {
  document.location.replace(this.href + '&t=' + $('#video .player')[0].getPlayerObj().video.currentTime);
  e.preventDefault();
});
