import { unionObj } from './misc';
import { addDelegatedEvent } from '../jslim/events';
import { xhr } from './xhr';

const defaultCallbacks = {
  progress: (e, message, fill, percentage, secondsRemaining) => {
    if (percentage >= 100) {
      message.innerText = 'Waiting for server...';
    } else {
      message.innerText = `${secondsRemaining} remaining (${Math.floor(percentage)}% )`;
    }
    fill.style.width = `${percentage}%`;
    message.style.left = `${percentage}%`;
		message.style.marginLeft = -message.offsetWidth / 2;
  },
  success: _ => _,
  error: (message, error) => {
    message.innerText = error;
  }
};

export function uploadForm(form, callbacks) {
	callbacks = unionObj(defaultCallbacks, callbacks || {});
	
  const message = form.querySelector('.progressor .message');
  const fill = form.querySelector('.progressor .fill');
  
	form.classList.add('uploading');
	
  xhr(form.getAttribute('method'), `${form.getAttribute('action')}/async`, new FormData(form), {
    progress: message ? function(percentage, secondsRemaining) {
			if (!message.classList.contains('plain')) message.classList.add('bobber');
			form.classList.toggle('waiting', percentage >= 100);
			callbacks.progress(message, fill, percentage, secondsRemaining);
		} : null,
    success: data => {
			form.classList.remove('uploading');
			form.dispatchEvent(new CustomEvent('ajax:complete', {
				detail: { data: data },
				bubbles: true,
				cancelable: true
			}));
      callbacks.success(data);
    },
    error: error => {
      form.classList.add('error');
			message.style.marginLeft = '';
      callbacks.error(message, error);
    },
    complete: () => {
      if (form.classList.contains('form-state-toggle')) {
        form.parentNode.classList.toggle(form.dataset.state);
      }
			form.classList.remove('waiting');
    }
  });
}

addDelegatedEvent(document, 'submit', 'form.async', (e, target) => {
  e.preventDefault();
  uploadForm(target);
});
