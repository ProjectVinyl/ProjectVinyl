/*
 * Ajax - A cleaner wrapper to hide the nastiness of fetch
 */
import { popupError } from '../components/popup';
import { csrfHeaders } from '../ujs/csrf';
import { QueryParameters } from './queryparameters';

export function handleError(response) {
  if (!response.ok) {
    throw new Error('Received error from server');
  }
  return response;
}

export function triggerAjaxComplete(data, sender) {
  (sender || document).dispatchEvent(new CustomEvent('ajax:complete', {
    detail: { data: data }, bubbles: true, cancelable: true
  }));
  return data;
}

function request(method, resource, data) {
  const params = csrfHeaders(method);
  if (data) {
    if (method == 'GET') {
      resource += '?' + new QueryParameters(data).toString();
    } else {
      params.body = JSON.stringify(data);
    }
  }
  resource = `/${resource.replace(/^[\/]*/g, '')}`;

  const promise = fetch(resource, params).catch(err => popupError(`${method} ${resource}\n\n${err}`)).then(handleError);
  promise.text = callback => promise.then(r => r.text()).then(triggerAjaxComplete).then(callback);
  promise.json = callback => promise.then(r => r.json()).then(triggerAjaxComplete).then(callback);
  return promise;
}

export const ajax = {
  get: (resource, data) => request('GET', resource, data),
  post: (resource, data) => request('POST', resource, data),
  put: (resource, data) => request('PUT', resource, data),
  patch: (resource, data) => request('PATCH', resource, data),
  delete: resource => request('DELETE', resource)
};
