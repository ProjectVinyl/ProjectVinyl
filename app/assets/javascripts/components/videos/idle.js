import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'mousemove', '.video', (event, target) => {
  target.dataset.idle = false;
  if (target.idleTimeout) {
    clearTimeout(target.idleTimeout);
  }
  target.idleTimeout = setTimeout(() => {
    target.dataset.idle = true;
  }, 5000);
});
