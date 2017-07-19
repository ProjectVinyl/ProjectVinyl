/**
 * External forms.
 */
import { ajax} from '../utils/ajax';
import { createWindow, centerWindow } from './window';
import { handleError } from '../utils/requests';
import { jSlim } from '../utils/jslim';

function createExternalForm(url, title, icon, maxWidth, thin) {
  const win = createWindow({
    icon: icon,
    title: title,
    content: '<div class="loader"><i class="fa fa-pulse fa-spinner"></i></div>'
  });
  
  if (thin) win.dom.classList.add('thin');
  if (maxWidth) win.content.style.maxWidth = maxWidth;
  
  ajax.get(url).text(function(html) {
    win.setContent(html);
    centerWindow(win);
  });
  
  return win;
}

jSlim.on(document, 'click', '[data-external-form]', function(e) {
  if (e.button !== 0) return;
  
  if (this.popup) {
    this.popup.show();
  } else {
    this.popup = createExternalForm(this.dataset.externalForm, this.dataset.title, this.dataset.icon, this.dataset.maxWidth, this.dataset.thin);
  }
  e.preventDefault();
});
