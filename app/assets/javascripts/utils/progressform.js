import { addDelegatedEvent } from '../jslim/events';
import { xhr } from './xhr';

export function uploadForm(form, callbacks, e) {
  if (e) e.preventDefault();
  const message = form.querySelector('.progressor .message'),
        fill = form.querySelector('.progressor .fill');
  
  form.classList.add('uploading');
  xhr(form.getAttribute('method'), `${form.action}.json`, new FormData(form), {
    progress: function(percentage, secondsRemaining) {
      if (!message.classList.contains('plain')) message.classList.add('bobber');
      form.classList.toggle('waiting', percentage >= 100);
      if (callbacks.progress) callbacks.progress(percentage, secondsRemaining, message, fill);
    },
    success: data => {
      form.classList.remove('uploading');
      form.dispatchEvent(new CustomEvent('ajax:complete', {
        detail: { data: data },
        bubbles: true, cancelable: true
      }));
      if (callbacks.success) callbacks.success(data, message);
    },
    error: error => {
      form.classList.add('error');
      message.style.marginLeft = '';
      callbacks.error(error, message);
    },
    complete: () => {
      if (form.classList.contains('form-state-toggle')) {
        form.parentNode.classList.toggle(form.dataset.state);
      }
      form.classList.remove('waiting');
    }
  });
}

const defaultCallbacks = {
  progress: (percentage, secondsRemaining, message, fill) => {
    message.innerText = percentage < 100 ? `${secondsRemaining} remaining (${Math.floor(percentage)}% )` : 'Waiting for server...';
    fill.style.width = `${percentage}%`;
    message.style.left = `${percentage}%`;
    message.style.marginLeft = -message.offsetWidth / 2;
  },
  error: (error, message) => {
    message.innerHTML = error;
  }
};

addDelegatedEvent(document, 'submit', 'form.async', (e, target) => {
  uploadForm(target, defaultCallbacks, e);
});
