import { addDelegatedEvent, dispatchEvent } from '../../jslim/events';
import { ajaxPost } from '../../utils/ajax';

addDelegatedEvent(document, 'ajax:complete', 'form.js-video-import', (e, target) => {

  showResponse(target, e.detail.data.error || e.detail.data.info)

  if (e.detail.data.error) {
    console.error(e.detail.data);
    triggerShake(target);
  } else if (!e.detail.data.info) {
    dispatchEvent('frame:frame_content', e.detail.data, document.getElementById('uploader_frame'));
    dispatchEvent('resolve', { resolution: 'true' }, target);
  }
});

addDelegatedEvent(document, 'change', 'form.js-video-import input[name=url]', (e, target) => {
  const container = target.closest('form.js-video-import');

  if (!target.value) {
    showResponse(container);
    return;
  }

  ajaxPost(`${target.form.getAttribute('action').split('?')[0]}.json`, {
    _intent: 'check',
    url: target.value
  }).json(data => {
    showResponse(container, data.error || data.info);

    if (e.detail.data.error) {
      console.error(e.detail.data);
      triggerShake(container);
    }
  });
});

function showResponse(target, msg) {
  const field = target.querySelector('.red');
  if (!field.dataset.original) {
    field.dataset.original = field.innerText;
  }
  field.innerText = msg || field.dataset.original;
}

function triggerShake(target) {
  const errorTarget = target.closest('.error-shakeable');
  if (errorTarget) {
    errorTarget.classList.remove('errored');
    requestAnimationFrame(() => {
      errorTarget.classList.add('errored');
      setTimeout(() => errorTarget.classList.remove('errored'), 1000);
    });
  }
}