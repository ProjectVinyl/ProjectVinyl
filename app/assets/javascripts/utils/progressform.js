import { Duration } from './duration';
import { unionObj, tryUnmarshal } from './misc';

function xhr(method, url, data, callbacks) {
  var csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  var xhr = new XMLHttpRequest();
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

const defaultCallbacks = {
  progress: function(e, message, fill, percentage, secondsRemaining) {
    if (percentage >= 100) {
      this.classList.add('waiting');
      message.innerText = 'Waiting for server...';
    } else {
      message.innerText = secondsRemaining.toString() + ' remaining (' + Math.floor(percentage) + '% )';
    }
    if (fill) fill.style.width = percentage + '%';
    if (message) message.style.left = percentage + '%';
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
}

function sendForm(form, callbacks) {
  var message = form.querySelector('.progressor .message');
  var fill = form.querySelector('.progressor .fill');
  
  var uploadedBytes = 0;
  var totalBytes = 0;
  
  var secondsRemaining = new Duration();
  var timeStarted = new Date();
  var timer;
  
  xhr(form.getAttribute('method'), form.getAttribute('action') + '/async', new FormData(form), {
    progress: function(e) {
      uploadedBytes = e.loaded;
      totalBytes = e.total;
      if (e.lengthComputable && message) {
        if (!message.classList.contains('plain')) message.classList.add('bobber');
        var percentage = Math.min((e.loaded / e.total) * 100, 100);
        callbacks.progress.apply(form, [message, fill, percentage, secondsRemaining]);
        message.style.marginLeft = -message.offsetWidth / 2;
      }
    },
    beforeSend: function() {
      timer = setInterval(function() {
        var timeElapsed = new Date() - timeStarted;
        var uploadSpeed = uploadedBytes / (timeElapsed / 1000);
        secondsRemaining = new Duration((totalBytes - uploadedBytes) / uploadSpeed);
      }, 1000);
      form.classList.add('uploading');
    },
    success: function(data) {
      if (timer) clearInterval(timer);
      form.classList.remove('waiting');
      callbacks.success.apply(form, [data]);
    },
    error: function(msg) {
      if (timer) clearInterval(timer);
      form.classList.remove('waiting');
      form.classList.add('error');
      callbacks.error.apply(form, [message, msg]);
    },
    complete: function() {
      if (form.classList.contains('form-state-toggle')) {
        form.parentNode.classList.toggle(form.dataset.state);
        form.classList.remove('waiting');
        form.classList.remove('uploading');
      }
    }
  });
}

export function uploadForm(form, callbacks) {
  sendForm(form, unionObj(defaultCallbacks, callbacks || {}));
}