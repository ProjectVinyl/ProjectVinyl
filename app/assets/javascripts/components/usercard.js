import { jSlim } from '../jslim.js';
import { ajax } from '../utils/ajax.js';

var hoverTimeout = null;
function closeUsercard() {
  jSlim.all('.hovercard.shown', function(card) {
    card.classList.remove('shown');
  });
}

function openUsercard(sender, usercard) {
  closeUsercard();
  sender.appendChild(usercard);
  if (hoverTimeout) {
    clearTimeout(hoverTimeout);
  }
  setTimeout(function() {
    usercard.classList.add('shown');
    hoverTimeout = setTimeout(function() {
      jSlim.all('.user-link:not(:hover) .hovercard.shown', function(a) {
        a.classList.remove('shown');
      });
    }, 500);
  }, 500);
}

jSlim.on(document, 'mouseover', '.user-link', function() {
  var id = this.dataset.id;
  var usercard = document.querySelector('.hovercard[data-id="' + id + '"]');
  if (!usercard) {
    usercard = document.createElement('DIV');
    usercard.classList.add('hovercard');
    usercard.dataset.id = id;
    usercard.addEventListener('mouseover', function(ev) {
      ev.stopPropagation();
    });
    var self = this;
    ajax.get('artist/hovercard', function(html) {
      usercard.innerHTML = html;
      openUsercard(self, usercard);
    }, { id: id }, 1);
  } else {
    openUsercard(this, usercard);
  }
});

jSlim.on(document, 'mouseout', '.user-link', closeUsercard);
