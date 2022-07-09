/**
  * Popup usercards because fancy
  */
import { addDelegatedEvent } from '../jslim/events';
import { ajaxGet } from '../utils/ajax';

function openUsercard(sender, usercard) {
  const newUsercard = usercard.cloneNode(true);
  sender.appendChild(newUsercard);
  requestAnimationFrame(() => newUsercard.classList.add('shown'));
  setTimeout(() => {
    if (usercard.parentNode) usercard.parentNode.removeChild(usercard);
  }, 500);
}

function closeUsercard() {
  document.querySelectorAll('.user-link .hovercard.shown').forEach(a => a.classList.remove('shown'));
}

addDelegatedEvent(document, 'mouseout', '.user-link', closeUsercard);
addDelegatedEvent(document, 'mouseover', '.user-link', function(e) {
  if (e.target.closest('.user-link-ignore')) return;
  closeUsercard();
  
  const id = parseInt(this.dataset.id) || 0;
  if (id <= 0) return;
  
  let usercard = document.querySelector(`.hovercard[data-id="${id}"]`);
  if (usercard) return openUsercard(this, usercard);
  
  this.insertAdjacentHTML('beforeend', `<div class="hovercard" data-id="${id}"></div>`);
  usercard = this.lastChild;
  
  ajaxGet(`/users/${id}/hovercard`).text(text => {
    usercard.innerHTML = text;
    usercard.classList.add('shown');
  });
});
