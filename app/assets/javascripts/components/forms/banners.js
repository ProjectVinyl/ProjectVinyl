import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'ajax:complete', 'form.js-banner-select', (e, target) => {
  target.querySelector('input[name="erase"]').checked = false;

  let url = e.detail.data.url;
  url = url ? `url('${e.detail.data.url}?${new Date().getTime()}')` : '';

  target.querySelector('.preview').style.backgroundImage = url;
  document.body.style.setProperty('--site-banner', url ? `${url} center center/cover #000` : '');
  document.body.style.setProperty('--custom-background', url);
});
