const ajax = (function() {

  function xhr(params) {
    if (params.xhr) {
      const xhr = params.xhr;
      params.xhr = function() {
        return xhr($.ajaxSettings.xhr());
      };
    }
    return $.ajax(params);
  }

  function request(method, resource, callback, data, direct) {
    xhr({
      type: method,
      datatype: 'text/plain',
      url: resource,
      success: direct ? callback : function(xml, type, ev) {
        callback(ev.status == 204 ? {} : JSON.parse(ev.responseText), ev.status);
      },
      error(d) {
        console.error(`${method} ${resource}\n\n${d.responseText}`);
      },
      data
    });
  }

  function sanitizeUrl(url) {
    while (url.indexOf('/') == 0) url = url.substring(1, url.length);
    return url;
  }

  function AjaxRequest(resource, callback, direct) {
    AjaxRequest.get(resource, callback, {}, direct);
  }

  return Object.freeze(extendObj(AjaxRequest, {
    form(form, e, callbacks) {
      if (!callbacks && !e.preventDefault) {
        callbacks = e;
        e = undefined;
      }
      if (e) e.preventDefault();
      const message = form.find('.progressor .message');
      const fill = form.find('.progressor .fill');
      let uploadedBytes = 0;
      let totalBytes = 0;
      let secondsRemaining = new Duration();
      const timeStarted = new Date();
      let timer;
      const callback_func = form.attr('data-callback');

      callbacks = callbacks || {};
      xhr({
        type: form.attr('method'),
        url: `${form.attr('action')}/async`,
        enctype: 'multipart/form-data',
        data: new FormData(form[0]),
        xhr(xhr) {
          if (xhr.upload) {
            xhr.upload.addEventListener('progress', e => {
              uploadedBytes = e.loaded;
              totalBytes = e.total;
              if (e.lengthComputable) {
                if (!message.hasClass('plain')) message.addClass('bobber');
                const percentage = Math.min((e.loaded / e.total) * 100, 100);
                if (callbacks.progress) {
                  callbacks.progress.apply(form, [e, message, fill, percentage, secondsRemaining]);
                } else {
                  if (percentage >= 100) {
                    form.addClass('waiting');
                    message.text('Waiting for server...');
                  } else {
                    message.text(`${secondsRemaining.toString()} remaining (${Math.floor(percentage)}% )`);
                  }
                  fill.css('width', `${percentage}%`);
                  message.css({
                    left: `${percentage}%`
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
        beforeSend() {
          timer = setInterval(() => {
            const timeElapsed = new Date() - timeStarted;
            const uploadSpeed = uploadedBytes / (timeElapsed / 1000);
            secondsRemaining = new Duration((totalBytes - uploadedBytes) / uploadSpeed);
          }, 1000);
          form.addClass('uploading');
        },
        success(data) {
          if (timer) clearInterval(timer);
          if (callbacks.success) {
            form.removeClass('waiting');
            return callbacks.success.apply(this, arguments);
          }
          if (callback_func && typeof window[callback_func] === 'function') {
            window[callback_func](form, data);
          } else if (data.ref) {
            document.location.href = data.ref;
          }

        },
        error(e, err, msg) {
          if (timer) clearInterval(timer);
          form.removeClass('waiting').addClass('error');
          if (callbacks.error) return callbacks.error(message, msg, e.responseText);
          message.text(e.responseText);
        },
        complete() {
          if (form.hasClass('form-state-toggle')) {
            form.parent().toggleClass(form.attr('data-state'));
            form.removeClass('waiting').removeClass('uploading');
          }
        },
        cache: false,
        contentType: false,
        processData: false
      });
    },
    post(resource, callback, direct, data) {
      request('POST', `/ajax/${sanitizeUrl(resource)}`, callback, data || {}, direct);
    },
    delete(resource, callback, direct) {
      request('DELETE', resource, callback, {}, direct);
    },
    get(resource, callback, data, direct) {
      request('GET', `/ajax/${sanitizeUrl(resource)}`, callback, data, direct);
    }
  }));
}());
