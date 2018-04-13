import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', '.dock-holder #dock-toggle, .dock-holder .dock-shadow', e => {
  e.target.closest('.dock-holder').classList.toggle('open');
});
