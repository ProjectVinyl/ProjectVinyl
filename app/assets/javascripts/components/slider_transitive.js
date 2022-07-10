import { addDelegatedEvent, dispatchEvent } from '../jslim/events';

export function touchSlider(dom) {
  dispatchEvent('slider:transitive', {}, dom);
}

function triggerInteraction(ev, target) {
  target.classList.add('interacting');

  if (target.interactingTimeout) {
    target.interactingTimeout = clearTimeout(target.interactingTimeout);
  }

  target.interactingTimeout = setTimeout(() => {
    target.classList.remove('interacting');
  }, 5000);
}

addDelegatedEvent(document, 'slider:transitive', '.slider-control', triggerInteraction);
addDelegatedEvent(document, 'slider:transitive', '.playback-controls', triggerInteraction);
