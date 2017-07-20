/*
 * Ajax
 * A cleaner wrapper to hide the nastiness of fetch/xhr
 */
import { popupError } from '../components/popup';

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
  }).then(function(response) {
    if (!response.ok) {
      throw new Error('Received error from server');
    }
    return response;
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

const ajax = Object.freeze({
  get: function(resource, data) {
    return request('GET', '/ajax/' + sanitizeUrl(resource), data);
  },
  post: function(resource, data) {
    return request('POST', '/ajax/' + sanitizeUrl(resource), data || {});
  },
  delete: function(resource) {
    return request('DELETE', resource, {});
  }
});

export { ajax };
