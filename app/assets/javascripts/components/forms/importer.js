import { addDelegatedEvent } from '../../jslim/events';

function dispatchEvent(event, data, sender) {
  (sender || document).dispatchEvent(new CustomEvent(event, {
    detail: { data: data }, bubbles: true, cancelable: true
  }));
  return data;
}

addDelegatedEvent(document, 'ajax:complete', 'form.js-video-import', (e, target) => {
  
  if (e.detail.data.error) {
    console.error(e.detail.data);
    target.querySelector('.red').innerText = e.detail.data.error;
    const errorTarget = target.closest('.error-shakeable');
    if (errorTarget) {
      errorTarget.classList.remove('errored');
      requestAnimationFrame(() => {
        errorTarget.classList.add('errored');
        setTimeout(() => errorTarget.classList.remove('errored'), 1000);
      });
    }
  } else {
    dispatchEvent('frame:frame_content', e.detail.data, document.getElementById('uploader_frame'));
  }
});
