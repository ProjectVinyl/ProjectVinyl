/**
 * External forms.
 */
import { ajaxGet } from '../../utils/ajax';
import { createWindow } from '../window';
import { moveToCenter } from '../draggable';
import { addDelegatedEvent } from '../../jslim/events';

function createExternalForm(target) {
  const win = createWindow({
    icon: target.dataset.icon,
    title: target.dataset.title,
    content: '<div class="loader"><i class="fa fa-pulse fa-spinner"></i></div>'
  });

  win.dom.classList.toggle('thin', target.dataset.thin);
  if (target.dataset.maxWidth) {
    win.content.style.maxWidth = target.dataset.maxWidth;
  }

  ajaxGet(target.dataset.externalForm).text(html => {
    win.setContent(html);
    moveToCenter(win.dom);
    document.dispatchEvent(new CustomEvent('ajax:externalform'), { cancelable: true });
  });

  return win;
}

addDelegatedEvent(document, 'click', '[data-external-form]', (e, target) => {
  if (e.button !== 0 || e.defaultPrevented) return;
  e.preventDefault();

  if (target.popup) {
    target.popup.show();
  } else {
    target.popup = createExternalForm(target);
  }
});
