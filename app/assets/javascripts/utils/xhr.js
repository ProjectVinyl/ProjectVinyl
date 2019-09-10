import { Duration } from './duration';
import { tryUnmarshal } from './misc';
import { csrfToken } from '../ujs/csrf';

export function xhr(method, url, data, callbacks) {
  const xhr = new XMLHttpRequest();
  const timeStarted = new Date();
  xhr.onreadystatechange = function() {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      try {
        if (xhr.status >= 200 && xhr.status < 300) {
          if (callbacks.success) callbacks.success(tryUnmarshal(xhr.responseXML || xhr.responseText));
        } else if (xhr.responseText) {
          if (callbacks.error) callbacks.error(xhr.responseText);
        }
      } catch (e) {
        console.error(e);
      }
      if (callbacks.complete) callbacks.complete();
    }
  };
  
  if (xhr.upload && callbacks.progress) {
    xhr.upload.addEventListener('progress', e => {
      if (!e.lengthComputable) return;
      
      const timeElapsed = new Date() - timeStarted;
      const uploadSpeed = e.loaded / (timeElapsed / 1000);
      const secondsRemaining = new Duration((e.total - e.loaded) / uploadSpeed);
      
      callbacks.progress(Math.min((e.loaded / e.total) * 100, 100), secondsRemaining);
    });
  }
  xhr.withCredentials = true;
  xhr.open(method, url, true);
  xhr.setRequestHeader('X-CSRF-Token', csrfToken());
  xhr.send(data);
}

export function sendForm(form, callbacks) {
  xhr(form.getAttribute('method'), `${form.action}.json`, new FormData(form), callbacks);
}
