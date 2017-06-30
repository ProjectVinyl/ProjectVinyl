import { Duration } from './duration.js';
import { extendObj } from './misc.js';
import { error } from '../components/popup.js';

function xhr(params) {
  var csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  var xhr = new XMLHttpRequest();
  if (params.xhr) params.xhr(xhr);
  if (params.method == 'GET') {
    params.url += '?' + queryPars(params.data);
  }
  xhr.open(params.method, params.url, true);
  xhr.setRequestHeader('X-CSRF-Token', csrf);
  xhr.setRequestHeader('Content-Type', params.enctype || 'application/x-www-form-urlencoded');
  xhr.onreadystatechange = function() {
    try {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status >= 200 && xhr.status < 300) {
              if (params.success) {
                params.success(xhr.responseXML || xhr.responseText, null, xhr);
              }
            } else {
                if (xhr.responseText && params.error) {
                  params.error(xhr.responseText);
                }
                console.error(xhr.responseText);
            }
            if (params.complete) params.complete();
        }
    } catch (e) {
      console.error(e);
    }
};
  if (params.beforeSend) params.beforeSend();
  xhr.send(params.data);
}

function queryPars(data) {
  if (!data) return null;
  return Object.keys(data).map(function(key) {
    return encodeURIComponent(key) + '=' + encodeURIComponent(data[key]);
  }).join('&');
}

function request(method, resource, callback, data, direct) {
  xhr({
    method: method,
    url: resource,
    success: direct ? callback : function(xml, type, ev) {
      callback(ev.status == 204 ? {} : JSON.parse(ev.responseText), ev.status);
    },
    error: function(msg) {
      error(method + ' ' + resource + '\n\n' + msg);
    },
    data: data
  });
}

function sanitizeUrl(url) {
  while (url.indexOf('/') == 0) url = url.substring(1, url.length);
  return url;
}

function AjaxRequest(resource, callback, direct) {
  AjaxRequest.get(resource, callback, {}, direct);
}

const ajax = Object.freeze(extendObj(AjaxRequest, {
  form: function(form, e, callbacks) {
    var message = form.find('.progressor .message');
    var fill = form.find('.progressor .fill');
    var uploadedBytes = 0;
    var totalBytes = 0;
    var secondsRemaining = new Duration();
    var timeStarted = new Date();
    var timer;
    var callbackFunc = form.attr('data-callback');
    
    if (!callbacks && !e.preventDefault) {
      callbacks = e;
      e = null;
    }
    if (e) e.preventDefault();
    
    callbacks = callbacks || {};
    xhr({
      method: form.attr('method'),
      url: form.attr('action') + '/async',
      enctype: 'multipart/form-data',
      data: new FormData(form[0]),
      xhr: function(xhr) {
        if (xhr.upload) {
          xhr.upload.addEventListener('progress', function(e) {
            uploadedBytes = e.loaded;
            totalBytes = e.total;
            if (e.lengthComputable) {
              if (!message.hasClass('plain')) message.addClass('bobber');
              var percentage = Math.min((e.loaded / e.total) * 100, 100);
              if (callbacks.progress) {
                callbacks.progress.apply(form, [e, message, fill, percentage, secondsRemaining]);
              } else {
                if (percentage >= 100) {
                  form.addClass('waiting');
                  message.text('Waiting for server...');
                } else {
                  message.text(secondsRemaining.toString() + ' remaining (' + Math.floor(percentage) + '% )');
                }
                fill.css('width', percentage + '%');
                message.css({
                  left: percentage + '%'
                });
              }
              if (callbacks.update) callbacks.update.apply(form, [e, percentage, secondsRemaining]);
              message.css({
                'margin-left': -message.outerWidth() / 2
              });
            }
          }, false);
        }
        return xhr;
      },
      beforeSend: function() {
        timer = setInterval(function() {
          var timeElapsed = new Date() - timeStarted;
          var uploadSpeed = uploadedBytes / (timeElapsed / 1000);
          secondsRemaining = new Duration((totalBytes - uploadedBytes) / uploadSpeed);
        }, 1000);
        form.addClass('uploading');
      },
      success: function(data) {
        if (timer) clearInterval(timer);
        if (callbacks.success) {
          form.removeClass('waiting');
          return callbacks.success.apply(form, arguments);
        }
        if (callbackFunc && typeof window[callbackFunc] === 'function') {
          window[callbackFunc](form, data);
        } else if (data.ref) {
          document.location.href = data.ref;
        }
        
      },
      error: function(msg) {
        if (timer) clearInterval(timer);
        form.removeClass('waiting').addClass('error');
        if (callbacks.error) return callbacks.error(message, '', msg);
        message.text(e.responseText);
      },
      complete: function() {
        if (form.hasClass('form-state-toggle')) {
          form.parent().toggleClass(form.attr('data-state'));
          form.removeClass('waiting').removeClass('uploading');
        }
      }
    });
  },
  post: function(resource, callback, direct, data) {
    request('POST', '/ajax/' + sanitizeUrl(resource), callback, data || {}, direct);
  },
  delete: function(resource, callback, direct) {
    request('DELETE', resource, callback, {}, direct);
  },
  get: function(resource, callback, data, direct) {
    request('GET', '/ajax/' + sanitizeUrl(resource), callback, data, direct);
  }
}));

// admin/files.html.erb
// artist/_edit.html.erb
// layouts/_reporter.html.erb
// layouts/application.html.erb
window.ajax = ajax;

export { ajax };
