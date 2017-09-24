/**
 * External forms.
 */
import { ajax} from '../utils/ajax';
import { createWindow, centerWindow } from './window';
import { popupError } from '../components/popup';
import { addDelegatedEvent } from '../jslim/events';

export function checkFormPrerequisits(group) {
	const required = group.querySelectorAll('[required], [data-required]');
	for (let i = 0; i < required.length; i++) {
		if (!validateInput(required[i])) {
			popupError('One or more required fields need to be filled in.');
			required[i].focus();
			return false;
		}
	}
	return true;
}

function validateInput(input) {
	if (input.tagName == 'INPUT' && input.type == 'checkbox') {
		return input.checked;
	}
	
	if (input.tagName == 'INPUT' || input.tagName == 'TEXTAREA') {
		return input.value && input.value.length;
	}
	
	const children = input.querySelectorAll('input');
	for (let i = 0; i < children.length; i++) {
		if (validateInput(children[i])) return true;
	}
	
	return false;
}

function createExternalForm(url, title, icon, maxWidth, thin) {
  const win = createWindow({
    icon: icon,
    title: title,
    content: '<div class="loader"><i class="fa fa-pulse fa-spinner"></i></div>'
  });
  
  if (thin) win.dom.classList.add('thin');
  if (maxWidth) win.content.style.maxWidth = maxWidth;
  
  ajax.get(url).text(html => {
    win.setContent(html);
    centerWindow(win);
  });
  
  return win;
}

addDelegatedEvent(document, 'click', '[data-external-form]', function(e) {
  if (e.button !== 0) return;
  
  if (this.popup) {
    this.popup.show();
  } else {
    this.popup = createExternalForm(this.dataset.externalForm, this.dataset.title, this.dataset.icon, this.dataset.maxWidth, this.dataset.thin);
  }
  e.preventDefault();
});
