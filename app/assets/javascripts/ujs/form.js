import { csrfParam, csrfToken } from './csrf';
import { handleError } from '../utils/requests';

document.addEventListener('submit', event => {
  const form = event.target.closest('form[data-remote]');
  if (!form) return;

  const url = form.action;
  const method = (form.method || form.dataset.method || 'POST').toUpperCase();
  const body = new FormData(form);
  body[csrfParam()] = csrfToken();
  
  event.preventDefault();
  fetch(url, { credentials: 'same-origin', method, body })
    .then(handleError)
    .then(response => {
      form.dispatchEvent(new CustomEvent('fetch:complete', {
        detail: response,
        bubbles: true,
        cancelable: true
      }));
    });
});
