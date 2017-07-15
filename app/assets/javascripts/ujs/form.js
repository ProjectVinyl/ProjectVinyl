import { csrfParam, csrfToken } from './csrf';
import { fetchHtml, handleError } from '../utils/requests';

const headers = { 'X-Requested-With': 'XMLHttpRequest' };

function doFetch(el, url, opts) {
  fetch(url, opts).then(handleError).then(response => {
    el.dispatchEvent(new CustomEvent('fetch:complete', {
      detail: response,
      bubbles: true,
      cancelable: true
    }));
  });
}

document.addEventListener('submit', event => {
  const form = event.target.closest('form[data-remote]');
  if (!form) return;

  const url    = form.action;
  const method = (form.method || form.dataset.method || 'POST').toUpperCase();
  const body   = new FormData(form);

  body.append(csrfParam(), csrfToken());
  
  event.preventDefault();

  doFetch(form, url, { credentials: 'same-origin', method, headers, body });
});

document.addEventListener('click', event => {
  const a = event.target.closest('a[data-remote]:not([data-method])');
  if (!a) return;

  const url    = a.href;
  const method = 'GET';

  event.preventDefault();

  doFetch(a, url, { credentials: 'same-origin', method, headers });
});
