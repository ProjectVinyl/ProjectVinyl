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
          callbacks.success(tryUnmarshal(xhr.responseXML || xhr.responseText));
        } else if (xhr.responseText) {
          callbacks.error(xhr.responseText);
        }
      } catch (e) {
        console.error(e);
      }
      callbacks.complete();
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
  xhr.open(method, url, true);
  xhr.setRequestHeader('X-CSRF-Token', csrfToken());
  xhr.send(data);
}
