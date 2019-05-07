import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'ajax:complete', 'form.js-banner-select', (e, target) => {
  const me = document.querySelector('#banner-upload');
  const banner = document.querySelector('#banner .banner-background');
  const erase = target.querySelector('input[name="erase"]');
  banner.style.background = erase.checked ? '' : `url(${me.dataset.path}?${new Date().getTime()}) center center/cover #000`;
});
