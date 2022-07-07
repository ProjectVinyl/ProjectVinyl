import { dispatchEvent, addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', 'a[data-resolve], button[data-resolve]', (event, target) => {
  if (event.button !== 0) return;
  const resolution = target.dataset.resolve;
  dispatchEvent('resolve', { resolution }, target);
});
