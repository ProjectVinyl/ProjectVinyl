/**
  * Popup usercards because fancy
  */
import { addDelegatedEvent } from '../jslim/events';
import { ajaxGet } from '../utils/ajax';

const INITIAL_CONTENT = `<li class="bio"><i class="fa fa-circle-o-notch fa-spin"></i></li>`;
const FAILED_CONTENT = `<li class="bio"><i class="fa red fa-warning"></i></div>`;
const loadedCards = {};

function loadCard(id) {
  if (!loadedCards[id]) {
    let pendingElement;
    ajaxGet(`/users/${id}/hovercard`).text(html => {
      if (pendingElement) {
        showCard(pendingElement, html);
      }

      loadedCards[id] = el => showCard(getCard(el), html);
    }).catch(() => {
      loadedCards[id] = null;
      if (pendingElement) {
        showCard(pendingElement, FAILED_CONTENT);
        pendingElement.classList.add('failed');
      }
    });

    loadedCards[id] = el => pendingElement = getCard(el);
  }
  
  return loadedCards[id];
}

function getCard(parent) {
  let card = parent.querySelector('.hovercard');
  if (!card) {
    parent.insertAdjacentHTML('beforeend', `<div class="hovercard loading transitional hidden">${INITIAL_CONTENT}</div>`);
    card = parent.lastChild;
    requestAnimationFrame(() => card.classList.remove('hidden'));
  }
  
  if (card.classList.contains('failed')) {
    card.classList.remove('failed');
    card.classList.add('loading');
    card.innerHTML = INITIAL_CONTENT;
  }
  
  return card;
}

function showCard(card, content) {
  card.innerHTML = content;
  card.classList.toggle('loading', content == FAILED_CONTENT);
}

function triggerCard(e, target) {
  if (e.target.closest('.user-link-ignore')) return;
  const id = parseInt(target.dataset.id) || 0;
  if (id > 0) {
    loadCard(id)(target);
  }
  e.preventDefault();
}

addDelegatedEvent(document, 'mouseover', '.user-link', triggerCard);
addDelegatedEvent(document, 'touchstart', '.user-link', triggerCard);
addDelegatedEvent(document, 'focus', '.user-link', triggerCard);
