/**
 * External forms.
 */

import { createWindow, closeWindow, handleEvents } from './window';
import { handleError } from '../utils/requests';
import { jSlim } from '../utils/jslim';

const formButton = '<button type="button" class="button-fw cancel blue right" data-resolve="false">Cancel</button>';
const spinner    = '<div class="loader"><i class="fa fa-pulse fa-spinner"></i></div>';

function createExternalForm({url, title}) {
  const [ overlay, win ] = createWindow({
    icon: 'fa-pencil',
    title: title,
    content: spinner,
    foot: formButton
  });

  const promise = handleEvents(overlay, win);
  const content = win.querySelector('.content');

  return fetch(url, { credentials: 'same-origin' })
    .then(handleError)
    .then(resp => resp.text())
    .then(html => content.innerHTML = html)
    .then(()   => promise);
}

jSlim.on(document, 'click', '[data-external-form]', function(event) {
  event.preventDefault();

  const url   = this.dataset.externalForm;
  const title = this.dataset.title;

  createExternalForm({url, title});
});
