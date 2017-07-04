import { Duration } from './duration';
import { extendObj } from './misc';
import { error } from '../components/popup';
import { Callbacks } from '../callbacks';

function xhr(params) {
  var csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    try {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status >= 200 && xhr.status < 300) {
          if (params.success) {
            params.success(xhr.responseXML || xhr.responseText, null, xhr);
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

function request(method, resource, data, callback) {
  var csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  var params = {
    method: method,
    credentials: 'same-origin',
    headers: new Headers({
      'Content-Type': 'application/x-www-form-urlencoded',
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
    error(method + ' ' + resource + '\n\n' + err);
    console.error(err);
  });
  if (callback) {
    return promise.then(function(response) {
      response.text().then(callback);
    });
  }
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
          fill.style.width = percentage + '%';
          message.style.left = percentage + '%';
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
      
      if (!Callbacks.execute(form.dataset.callback)) {
        if (data.ref) {
          document.location.href = data.ref;
        }
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

function AjaxRequest(resource, callback, direct) {
  AjaxRequest.get(resource, callback, {}, direct);
}

const ajax = Object.freeze(extendObj(AjaxRequest, {
  get: function(resource, data, callback) {
    return request('GET', '/ajax/' + sanitizeUrl(resource), data, callback);
  },
  post: function(resource, data, callback) {
    return request('POST', '/ajax/' + sanitizeUrl(resource), data || {}, callback);
  },
  delete: function(resource, callback) {
    return request('DELETE', resource, {}, callback);
  },
  form: function(form, e, callbacks) {
    if (!callbacks && !e.preventDefault) {
      callbacks = e;
      e = null;
    }
    if (e) e.preventDefault();
    sendForm(form, e, callbacks || {});
  }
}));

// admin/files.html.erb
// artist/_edit.html.erb
// layouts/_reporter.html.erb
// layouts/application.html.erb
window.ajax = ajax;

export { ajax };
