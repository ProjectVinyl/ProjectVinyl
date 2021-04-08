import { addDelegatedEvent } from '../jslim/events';
import { sendForm } from './xhr';
import { triggerAjaxComplete } from './ajax';
import { round } from '../utils/math';
import { createWindow } from '../components/window';

export function uploadForm(form, callbacks, e) {
  if (e) e.preventDefault();
  const message = form.querySelector('.progressor .message'),
        fill = form.querySelector('.progressor .fill');
  
  form.classList.add('uploading');
  
  let percent = 0;
  
  sendForm(form, {
    progress(percentage, secondsRemaining) {
      percent = percentage;

      if (message && !message.classList.contains('plain')) {
        message.classList.add('bobber');
      }

      form.classList.toggle('waiting', percentage >= 100);

      if (message && callbacks.progress) {
        callbacks.progress(percentage, secondsRemaining, message, fill);
      }
    },
    success(data) {
      form.classList.remove('uploading');
      triggerAjaxComplete(data, form);
      if (callbacks.success) callbacks.success(data, message);
    },
    error(error) {
      form.classList.add('error');
      if (message) {
        message.style.marginLeft = '';
      }
      callbacks.error(error, message, percent);
    },
    complete() {
      if (form.classList.contains('form-state-toggle')) {
        form.parentNode.classList.toggle(form.dataset.state);
      }
      form.classList.remove('waiting');
    }
  });
}

export const defaultCallbacks = {
  progress: (percentage, secondsRemaining, message, fill) => {
    message.innerText = percentage < 100 ? `${round(secondsRemaining, 2)}s remaining (${Math.floor(percentage)}% )` : 'Waiting for server...';
    fill.style.setProperty('--status-progress', `${percentage}%`);
    message.style.setProperty('--content-offset', `calc(${percentage}% - ${message.offsetWidth / 2}px)`);
  },
  error: (error, message, percentage) => {
    if (error.length > 200) {
      createWindow({
        title: 'Error',
        content: error
      });
    } else {
      message.innerText = error;
      message.style.setProperty('--content-offset', `calc(${percentage}% - ${message.offsetWidth / 2}px)`);
    }
  }
};

addDelegatedEvent(document, 'submit', 'form.async', (e, target) => {
  uploadForm(target, defaultCallbacks, e);
});
