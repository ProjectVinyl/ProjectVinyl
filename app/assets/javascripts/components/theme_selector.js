import { addDelegatedEvent } from '../jslim/events';
import { cookies } from '../utils/cookies';

addDelegatedEvent(document, 'change', '#theme', (e, target) => {
  cookies.set('site_theme', target.value);
  document.location.href = document.location.href;
});
