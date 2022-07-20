import { addDelegatedEvent } from '../../jslim/events';
import { applyCardAttributes, getInput } from './attribute_sync';

function seekTo(card, timeInput) {
  const editor = card.closest('.js-video-card-editor');
  if (editor.player) {
    editor.player.skipTo(parseFloat(timeInput.value));
  }
}

addDelegatedEvent(document, 'click', '.js-video-card-editor .card-list .card', (ev, target) => {
  seekTo(target, target.querySelector('input[name="video[cards[][start_time]]"]'));
});

function applyTimeChange(target) {
  const card = target.closest('.card');
  
  const start = getInput(card, 'start_time');
  const end = getInput(card, 'end_time');

  if (parseFloat(start.value) > parseFloat(end.value)) {
    end.value = start.value;
  }
  
  seekTo(card, target);
  applyCardAttributes(card);
}

addDelegatedEvent(document, 'change', '.js-video-card-editor .card-list .time-input', (ev, target) => applyTimeChange(target));
addDelegatedEvent(document, 'keyup', '.js-video-card-editor .card-list .time-input', (ev, target) => applyTimeChange(target));
addDelegatedEvent(document, 'removed', '.js-video-card-editor .card-list', (ev, target) => {
  target
    .closest('.js-video-card-editor')
    .querySelectorAll(`[data-card-id="${ev.detail.target.dataset.cardId}"]`)
    .forEach(el => {
      el.remove();
  });
});
