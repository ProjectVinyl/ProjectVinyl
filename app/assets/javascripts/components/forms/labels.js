import { addDelegatedEvent } from '../../jslim/events';

function toggleFocus(e, on) {
  const label = e.target.closest('label');
  if (label) label.classList.toggle('focus', on);
}

// Hover events for labels in the search forms (and other places, maybe, eventually)
addDelegatedEvent(document, 'focusin', 'label input, label select, label textarea', e => toggleFocus(e, true));
addDelegatedEvent(document, 'focusout', 'label input, label select, label textarea', e => toggleFocus(e, false));
