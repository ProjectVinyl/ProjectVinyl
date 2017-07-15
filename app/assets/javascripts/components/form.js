/**
 * External forms.
 */

import { createWindow, closeWindow, centerWindow } from './window';
import { handleError } from '../utils/requests';
import { jSlim } from '../utils/jslim';

// TODO: Reimplement persistent popups so we don't have to keep reloading these. -_____-
function createExternalForm(url, title, icon, maxWidth, thin) {
  const win = createWindow({
    icon: icon,
    title: title,
    content: '<div class="loader"><i class="fa fa-pulse fa-spinner"></i></div>',
    foot: '' // we don't want or need a footer here.
  });
  
  if (thin) win.overlay.classList.add('thin');
  
  const content = win.dom.querySelector('.content');
  
  var foot = win.overlay.querySelector('.foot');
  foot.parentNode.removeChild(foot);
  
  if (maxWidth) {
    content.style.maxWidth = maxWidth;
  }
  
  return fetch(url, { credentials: 'same-origin' })
    .then(handleError).then(resp => resp.text()).then(function(html) {
      content.innerHTML = html;
      centerWindow(win);
    });
}

jSlim.on(document, 'click', '[data-external-form]', function(e) {
  if (e.button !== 0) return;
  createExternalForm(this.dataset.externalForm, this.dataset.title, this.dataset.icon, this.dataset.maxWidth, this.dataset.thin);
  e.preventDefault();
});
