import { jSlim } from '../utils/jslim';
import { ajax } from '../utils/ajax';

function openUsercard(sender, usercard) {
  const newUsercard = usercard.cloneNode(true);
  sender.appendChild(newUsercard);
  requestAnimationFrame(() => {
    newUsercard.classList.add('shown');
  });
  setTimeout(() => {
    usercard.parentNode.removeChild(usercard);
  }, 500);
}

function closeUsercard() {
  jSlim.all('.user-link .hovercard.shown', a => {
    a.classList.remove('shown');
  });
}

jSlim.on(document, 'mouseout', '.user-link', closeUsercard);
jSlim.on(document, 'mouseover', '.user-link', function(e) {
  if (e.target.closest('.user-link-ignore')) return;
  closeUsercard();
  
  const id = this.dataset.id;
  
  let usercard = document.querySelector('.hovercard[data-id="' + id + '"]');
  if (usercard) {
    return openUsercard(this, usercard);
  }
  
  usercard = document.createElement('DIV');
  usercard.classList.add('hovercard');
  usercard.dataset.id = id;
  this.appendChild(usercard);
  
  ajax.get('users/' + id + '/hovercard').text(text => {
    usercard.innerHTML = text;
    usercard.classList.add('shown');
  });
});
