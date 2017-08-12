/*
 * Ajax
 * A cleaner wrapper to hide the nastiness of fetch/xhr
 */
import { jSlim } from './jslim';
import { popupError } from '../components/popup';

var csrf = '';
jSlim.ready(() => {
  csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
});

function requestHeaders(method) {
  return {
    method: method,
    credentials: 'same-origin',
    headers: new Headers({
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': csrf
    })
  };
}

function sanitizeUrl(url) {
  return url.replace(/^[\/]*/g, '');
}

function queryPars(data) {
  if (typeof data === 'string') return data;
  return Object.keys(data).map(key => encodeURIComponent(key) + '=' + encodeURIComponent(data[key])).join('&');
}

function request(resource, params) {
  const promise = fetch(resource, params).catch(err => {
    popupError(params.method + ' ' + resource + '\n\n' + err);
  }).then(r => {
    if (!r.ok) {
      throw new Error('Received error from server');
    }
    return r;
  });
  return {
    text: function(callback) {
      return promise.then(r => r.text()).then(ajaxComplete).then(callback);
    },
    json: function(callback) {
      return promise.then(r => r.json()).then(ajaxComplete).then(callback);
    }
  };
}

function ajaxComplete(data) {
  document.dispatchEvent(new CustomEvent('ajax:complete', {
    detail: {
      data: data
    },
    cancelable: true
  }));
  return data;
}

export function AjaxRequest(method, resource, data) {
  const params = requestHeaders(method);
  if (data) {
    if (method == 'GET') {
      resource += '?' + queryPars(data);
    } else {
      params.body = queryPars(data);
    }
  }
  return request('/' + sanitizeUrl(resource), params);
}

export const ajax = {
  get: function(resource, data) {
    return AjaxRequest('GET', resource, data);
  },
  post: function(resource, data) {
    return AjaxRequest('POST', resource, data);
  },
  put: function(resource, data) {
    return AjaxRequest('PUT', resource, data);
  },
  patch: function(resource, data) {
    return AjaxRequest('PATCH', resource, data);
  },
  delete: function(resource) {
    return AjaxRequest('DELETE', resource);
  }
};
