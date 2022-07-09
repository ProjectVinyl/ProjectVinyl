/*
 * Ajax - A cleaner wrapper to hide the nastiness of fetch
 */
import { dispatchEvent } from '../jslim/events';
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
  return dispatchEvent('ajax:complete', data, sender);
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

export function ajaxGet(resource, data) {
  return request('GET', resource, data);
}
export function ajaxPost(resource, data) {
  return request('POST', resource, data);
}
export function ajaxPut(resource, data) {
  return request('PUT', resource, data);
}
export function ajaxDelete(resource) {
  return request('DELETE', resource);
}
export function ajaxPatch(resource, data) {
  return request('PATCH', resource, data);
}
