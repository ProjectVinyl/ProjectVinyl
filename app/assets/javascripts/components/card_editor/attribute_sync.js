import { addDelegatedEvent } from '../../jslim/events';

const attributes = ['top', 'left', 'width', 'height', 'start_time', 'end_time'];

export function getInput(card, key) {
  return card.querySelector(`input[name="video[cards[][${key}]]"]`);
}

function setAttribute(card, key, value) {
  getInput(card, key).value = value;
}

function getAttributes(card) {
  const data = {};
  attributes.forEach(key => {
    data[key] = parseFloat(getInput(card, key).value);
  });
  return data;
}

export function applyCardAttributes(card) {
  const editor = card.closest('.js-video-card-editor');
  const id = card.dataset.cardId;
  
  const data = getAttributes(card);

  editor.querySelectorAll(`.story-cards-root [data-card-id="${id}"`).forEach(el => {
    delete el.style.top;
    delete el.style.left;
    el.style.setProperty('--x', `${data.left}%`);
    el.style.setProperty('--y', `${data.top}%`);
    el.style.setProperty('--w', `${data.width}%`);
    el.style.setProperty('--h', `${data.height}%`);
    el.dataset.start = data.start_time;
    el.dataset.end = data.end_time;
  });
}

export function updateCardForm(moveable) {
  const editor = moveable.closest('.js-video-card-editor');
  const id = moveable.dataset.cardId;
  const card = editor.querySelector(`.card-list .card[data-card-id="${id}"]`);
  
  if (!card) {
    return;
  }
  
  setAttribute(card, 'top', parseFloat(moveable.style.top || moveable.style.getPropertyValue('--y')));
  setAttribute(card, 'left', parseFloat(moveable.style.left || moveable.style.getPropertyValue('--x')));
  setAttribute(card, 'width', parseFloat(moveable.style.getPropertyValue('--w')));
  setAttribute(card, 'height', parseFloat(moveable.style.getPropertyValue('--h')));
}

addDelegatedEvent(document, 'draggable:release', '.js-video-card-editor [data-card-id]', (ev, target) => {
  console.log('release');
  requestAnimationFrame(() => updateCardForm(target));
});
