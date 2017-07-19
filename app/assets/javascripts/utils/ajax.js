import { Duration } from './duration';
import { extendObj } from './misc';
import { popupError } from '../components/popup';

function xhr(params) {
  var csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    try {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status >= 200 && xhr.status < 300) {
          if (params.success) {
            let data = xhr.responseXML || xhr.responseText;
            try { data = JSON.parse(data) } catch(ignored) {} // try to unmarshal
            params.success(data, null, xhr);
          }
        } else if (xhr.responseText) {
          if (params.error) params.error(xhr.responseText);
          console.error(xhr.responseText);
        }
        if (params.complete) params.complete();
      }
    } catch (e) {
      console.error(e);
    }
  };
  if (params.progress && xhr.upload) xhr.upload.addEventListener('progress', params.progress);
  if (params.beforeSend) params.beforeSend();
  xhr.open(params.method, params.url, true);
  xhr.setRequestHeader('X-CSRF-Token', csrf);
  xhr.send(params.data);
}

function request(method, resource, data) {
  var csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  var params = {
    method: method,
    credentials: 'same-origin',
    headers: new Headers({
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': csrf
    })
  };
  if (data) {
    if (method === 'GET') {
      resource += '?' + queryPars(data);
    } else {
      params.body = queryPars(data);
    }
  }
  var promise = fetch(resource, params).catch(function(err) {
    popupError(method + ' ' + resource + '\n\n' + err);
  });
  return {
    text: function(callback) {
      promise.then(function(response) {
        response.text().then(callback);
      });
    },
    json: function(callback) {
      promise.then(function(response) {
        response.json().then(callback);
      });
    },
    then: function(callback) {
      return promise.then(callback);
    }
  };
}

function queryPars(data) {
  if (!data) return null;
  if (typeof data === 'string') return data;
  return Object.keys(data).map(function(key) {
    return encodeURIComponent(key) + '=' + encodeURIComponent(data[key]);
  }).join('&');
}

function sanitizeUrl(url) {
  while (url.indexOf('/') == 0) url = url.substring(1, url.length);
  return url;
}

function sendForm(form, e, callbacks) {
  var message = form.querySelector('.progressor .message');
  var fill = form.querySelector('.progressor .fill');
  
  var uploadedBytes = 0;
  var totalBytes = 0;
  var secondsRemaining = new Duration();
  var timeStarted = new Date();
  var timer;
  var params = {
    method: form.getAttribute('method'),
    url: form.getAttribute('action') + '/async',
    data: new FormData(form),
    progress: function(e) {
      uploadedBytes = e.loaded;
      totalBytes = e.total;
      if (e.lengthComputable && message) {
        if (!message.classList.contains('plain')) message.classList.add('bobber');
        var percentage = Math.min((e.loaded / e.total) * 100, 100);
        if (callbacks.progress) {
          callbacks.progress.apply(form, [e, message, fill, percentage, secondsRemaining]);
        } else {
          if (percentage >= 100) {
            form.classList.add('waiting');
            message.innerText = 'Waiting for server...';
          } else {
            message.innerText = secondsRemaining.toString() + ' remaining (' + Math.floor(percentage) + '% )';
          }
          if (fill) fill.style.width = percentage + '%';
          if (message) message.style.left = percentage + '%';
        }
        if (callbacks.update) {
          callbacks.update.apply(form, [e, percentage, secondsRemaining]);
        }
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
      if (callbacks.success) {
        form.classList.remove('waiting');
        return callbacks.success.apply(form, arguments);
      }
      
      form.dispatchEvent(new CustomEvent('ajax:complete', { // wat
        detail: { data },
        bubbles: true,
        cancelable: true
      }));
      
      if (data.ref) {
        document.location.href = data.ref;
      }
    },
    error: function(msg) {
      if (timer) clearInterval(timer);
      form.classList.remove('waiting');
      form.classList.add('error');
      if (callbacks.error) return callbacks.error(message, '', msg);
      message.innerText = e.responseText;
    }
  };
  if (form.classList.contains('form-state-toggle')) {
    params.complete = function() {
      form.parentNode.classList.toggle(form.dataset.state);
      form.classList.remove('waiting');
      form.classList.remove('uploading');
    };
  }
  xhr(params);
}

const ajax = Object.freeze({
  get: function(resource, data) {
    return request('GET', '/ajax/' + sanitizeUrl(resource), data);
  },
  post: function(resource, data) {
    return request('POST', '/ajax/' + sanitizeUrl(resource), data || {});
  },
  delete: function(resource) {
    return request('DELETE', resource, {});
  },
  form: function(form, e, callbacks) {
    if (!callbacks && !e.preventDefault) {
      callbacks = e;
      e = null;
    }
    if (e) e.preventDefault();
    sendForm(form, e, callbacks || {});
  }
});

export { ajax };
