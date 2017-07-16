/**
 * External forms.
 */

import { createWindow, centerWindow } from './window';
import { handleError } from '../utils/requests';
import { jSlim } from '../utils/jslim';

// TODO: Reimplement persistent popups so we don't have to keep reloading these. -_____-
function createExternalForm(url, title, icon, maxWidth, thin) {
  const win = createWindow({
    icon: icon,
    title: title,
    content: '<div class="loader"><i class="fa fa-pulse fa-spinner"></i></div>'
  });
  
  if (thin) win.dom.classList.add('thin');
  if (maxWidth) win.content.style.maxWidth = maxWidth;
  
  return fetch(url, {
    credentials: 'same-origin'
  }).then(handleError).then(function(resp) {
    return resp.text();
  }).then(function(html) {
    win.setContent(html);
    centerWindow(win);
  });
}

jSlim.on(document, 'click', '[data-external-form]', function(e) {
  if (e.button !== 0) return;
  createExternalForm(this.dataset.externalForm, this.dataset.title, this.dataset.icon, this.dataset.maxWidth, this.dataset.thin);
  e.preventDefault();
});
