/*
 * Ajax
 * A cleaner wrapper to hide the nastiness of fetch/xhr
 */
import { jSlim } from './jslim';
import { popupError } from '../components/popup';

var csrf = '';
jSlim.ready(function() {
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
  return Object.keys(data).map(function(key) {
    return encodeURIComponent(key) + '=' + encodeURIComponent(data[key]);
  }).join('&');
}

function request(resource, params) {
  const promise = fetch(resource, params).catch(function(err) {
    popupError(params.method + ' ' + domain + path + '\n\n' + err);
  }).then(function(response) {
    if (!response.ok) {
      throw new Error('Received error from server');
    }
    return response;
  });
  return {
    text: function(callback) {
      return promise.then(function(response) {
        return response.text();
      }).then(callback);
    },
    json: function(callback) {
      return promise.then(function(response) {
        return response.json();
      }).then(callback);
    }
  };
}

export const ajax = {
  get: function(resource, data) {
    if (data) {
      resource += '?' + queryPars(data);
    }
    return request('/ajax/' + sanitizeUrl(resource), requestHeaders('GET'));
  },
  post: function(resource, data) {
    const params = requestHeaders('POST');
    if (data) {
      params.body = queryPars(data);
    }
    return request('/ajax/' + sanitizeUrl(resource), params);
  },
  delete: function(resource) {
    return request('/' + sanitizeUrl(resource), requestHeaders('DELETE'));
  }
};
