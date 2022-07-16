import { dispatchEvent } from '../jslim/events';

export const DEFAULT_DURATION = 3000;

export function notify(content, showDuration) {
  document.body.insertAdjacentHTML('beforeend', `<div class="notifier-notification transitional hidden" />`);
  const element = document.body.lastChild;
  element.innerText = content;
  requestAnimationFrame(() => {
    element.classList.remove('hidden');
    dispatchEvent('notifier:shown', { content }, element);

    setTimeout(() => {
      element.classList.add('hidden');
      dispatchEvent('notifier:hidden', { content }, element);
      setTimeout(() => element.remove(), DEFAULT_DURATION);
    }, showDuration);
  });

  return element;
}

export function notifyException(message, exception) {
  console.error(exception);
  return notify(message, DEFAULT_DURATION);
}
