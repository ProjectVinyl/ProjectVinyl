/*
 * Ajax - A cleaner wrapper to hide the nastiness of fetch/xhr
 */
import { popupError } from '../components/popup';
import { csrfToken } from '.../ujs/csrf';
import { QueryParameters } from 'queryparameters';

export function handleError(response) {
  if (!response.ok) {
    throw new Error('Received error from server');
  }
  return response;
}

export function AjaxRequest(method, resource, data) {
  const params = {
		method: method,
		credentials: 'same-origin',
		headers: {
			'Content-Type': 'application/json',
			'X-Requested-With': 'XMLHttpRequest',
			'X-CSRF-Token': csrfToken()
		}
	};
  if (data) {
		data = new QueryParameters(data);
    if (method == 'GET') {
      resource += `?${data}`;
    } else {
      params.body = JSON.stringify(data.values);
    }
  }
  resource = `/${resource.replace(/^[\/]*/g, '')}`;
	
	const promise = fetch(resource, params).catch(err =>
		popupError(`${params.method} ${resource}\n\n${err}`)).then(handleError);
	const send = (convert, callback) => promise.then(convert).then(data => {
		document.dispatchEvent(new CustomEvent('ajax:complete', {
			detail: { data: data }, cancelable: true
		}));
		return callback(data);
	});
	
  return {
    text: callback => send(r => r.text(), callback),
    json: callback => send(r => r.json(), callback)
  };
}

export const ajax = {
  get: (resource, data) => AjaxRequest('GET', resource, data),
  post: (resource, data) => AjaxRequest('POST', resource, data),
  put: (resource, data) => AjaxRequest('PUT', resource, data),
  patch: (resource, data) => AjaxRequest('PATCH', resource, data),
  delete: resource => AjaxRequest('DELETE', resource)
};
