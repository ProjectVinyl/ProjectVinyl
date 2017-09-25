import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', '.state-toggle', (e, target) => {
  if (e.which != 1 && e.button != 0) return;
  e.preventDefault();
  
  target.classList.toggle('toggled');
  
  let parent = target.dataset.parent;
  parent = parent ? target.closest(parent) : target.parentNode;
  
  const active = parent.classList.contains('active');
  parent.classList.toggle(target.dataset.state);
  target.dispatchEvent(new CustomEvent('toggle', {
    detail: { active: active },
    bubbles: true
  }));
});
