/*
 * For anything that counts anything.
 */
import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'removed', '[data-count-targets]', (e, target) => {
  const targets = target.dataset.countTargets;
  const count = target.querySelectorAll(`[data-countable="${targets}"]`).length;

  const countSpan = target.querySelector('.count');
  const numberSpan = countSpan.querySelector('.number');

  numberSpan.innerText = count;
  countSpan.classList.toggle('hidden', countSpan.classList.contains('hideable') && !count);
});
