import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', '.state-toggle', (e, target) => {
  if (e.target.tagName == 'INPUT' || (e.which != 1 && e.button != 0)) return;
  if (target.dataset.bubble !== 'true') {
    e.preventDefault();
  }

  target.classList.toggle('toggled');
  
  let parent = target.dataset.parent;
  parent = parent ? target.closest(parent) : target.parentNode;
  
  const active = parent.classList.contains(target.dataset.state);
  parent.classList.toggle(target.dataset.state);
  target.dispatchEvent(new CustomEvent('toggle', {
    detail: { active: active },
    bubbles: true
  }));
});
