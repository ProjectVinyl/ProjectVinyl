import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', '.state-set', (e, target) => {
  if ((e.which != 1 && e.button != 0) || e.defaultPrevented) return;
  e.preventDefault();
  
  target.classList.toggle('toggled');
  
  let parent = target.dataset.parent;
  parent = parent ? target.closest(parent) : target.parentNode;
  
  parent.dataset.state = target.dataset.state;
});
