import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'error', 'img[data-fallback-src]', (e, target) => {
  if (target.src != target.dataset.fallbackSrc) {
    target.src = target.dataset.fallbackSrc;
  }
}, true);
