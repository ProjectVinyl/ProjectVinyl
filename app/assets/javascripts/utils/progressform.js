import { Duration } from './duration';
import { unionObj, tryUnmarshal } from './misc';
import { jSlim } from './jslim';

function xhr(method, url, data, callbacks) {
  const csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  const xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    try {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status >= 200 && xhr.status < 300) {
          callbacks.success(tryUnmarshal(xhr.responseXML || xhr.responseText), null, xhr);
        } else if (xhr.responseText) {
          callbacks.error(xhr.responseText);
        }
        callbacks.complete();
      }
    } catch (e) {
      console.error(e);
    }
  };
  if (xhr.upload) xhr.upload.addEventListener('progress', callbacks.progress);
  callbacks.beforeSend();
  xhr.open(method, url, true);
  xhr.setRequestHeader('X-CSRF-Token', csrf);
  xhr.send(data);
}

function sendForm(form, callbacks) {
  const message = form.querySelector('.progressor .message');
  const fill = form.querySelector('.progressor .fill');
  
  let uploadedBytes = 0;
  let totalBytes = 0;
  
  let secondsRemaining = new Duration();
  const timeStarted = new Date();
  let timer;
  
  xhr(form.getAttribute('method'), `${form.getAttribute('action')}/async`, new FormData(form), {
    progress: e => {
      uploadedBytes = e.loaded;
      totalBytes = e.total;
      if (e.lengthComputable && message) {
        if (!message.classList.contains('plain')) message.classList.add('bobber');
        const percentage = Math.min((e.loaded / e.total) * 100, 100);
        callbacks.progress.apply(form, [message, fill, percentage, secondsRemaining]);
        message.style.marginLeft = -message.offsetWidth / 2;
      }
    },
    beforeSend: () => {
      timer = setInterval(() => {
        const timeElapsed = new Date() - timeStarted;
        const uploadSpeed = uploadedBytes / (timeElapsed / 1000);
        secondsRemaining = new Duration((totalBytes - uploadedBytes) / uploadSpeed);
      }, 1000);
      form.classList.add('uploading');
    },
    success: data => {
      if (timer) clearInterval(timer);
      form.classList.remove('waiting');
      callbacks.success.apply(form, [data]);
    },
    error: msg => {
      if (timer) clearInterval(timer);
      form.classList.remove('waiting');
      form.classList.add('error');
      callbacks.error.apply(form, [message, msg]);
    },
    complete: () => {
      if (form.classList.contains('form-state-toggle')) {
        form.parentNode.classList.toggle(form.dataset.state);
        form.classList.remove('waiting');
        form.classList.remove('uploading');
      }
    }
  });
}

const defaultCallbacks = {
  progress: function(e, message, fill, percentage, secondsRemaining) {
    if (percentage >= 100) {
      this.classList.add('waiting');
      message.innerText = 'Waiting for server...';
    } else {
      message.innerText = `${secondsRemaining} remaining (${Math.floor(percentage)}% )`;
    }
    if (fill) fill.style.width = `${percentage}%`;
    if (message) message.style.left = `${percentage}%`;
  },
  success: function(data) {
    this.dispatchEvent(new CustomEvent('ajax:complete', {
      detail: {
        data: data
      },
      bubbles: true,
      cancelable: true
    }));
    
    if (data.ref) {
      document.location.href = data.ref;
    }
  },
  error: function(message, msg) {
    message.innerText = msg;
  }
};

export function uploadForm(form, callbacks) {
  sendForm(form, unionObj(defaultCallbacks, callbacks || {}));
}

jSlim.on(document, 'submit', 'form.async', (e, target) => {
  e.preventDefault();
  uploadForm(target);
});
