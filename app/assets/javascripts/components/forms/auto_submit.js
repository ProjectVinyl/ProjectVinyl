import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'change', 'form .auto-submit', (e, target) => {
  const form = target.closest('form');
  let button = form.querySelector('button[type="submit"]');
  if (!button) {
    form.insertAdjacentHTML('beforeend', '<button class="hidden" type="submit" />');
    button = form.lastChild;
  }
  button.click();
});
