import { addDelegatedEvent } from '../jslim/events';

// Hover events for labels in the search forms (and other places, maybe, eventually)
addDelegatedEvent(document, 'focusin', 'label input, label select, label textarea', (e) => {
  e.target.closest('label').classList.add('focus');
});

addDelegatedEvent(document, 'focusout', 'label input, label select, label textarea', (e) => {
  e.target.closest('label').classList.remove('focus');
});
