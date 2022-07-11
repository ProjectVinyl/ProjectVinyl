import { addDelegatedEvent } from '../jslim/events';
import { ajaxPut } from '../utils/ajax';
import { formatNumber, MAX_DISPLAYED_VALUE } from '../utils/numbers';

function redrawCounter(me, offset) {
  const updateUI = state => {
    me.dataset.count = state.count;
    me.dataset.display = formatNumber(state.count, MAX_DISPLAYED_VALUE);
    redrawBar(me);
  };

  me.classList.toggle('liked', offset > 0);
  updateUI({ count: (parseInt(me.dataset.count) || 0) + offset });

  return updateUI;
}

function redrawBar(me) {
  const bar = me.parentNode.querySelector('.rating-bar');
  if (bar) {
    const likes = parseInt(me.parentNode.querySelector('.like').dataset.count);
    const dislikes = parseInt(me.parentNode.querySelector('.dislike').dataset.count);
    const total = likes + dislikes;
    const percentage = total <= 0 ? 0 : likes / total;

    bar.style.setProperty('--bar-percentage', percentage);
    bar.dataset.totalVotes = total;
    bar.title = `${formatNumber(percentage * 100, MAX_DISPLAYED_VALUE)}%`;
  }
}

addDelegatedEvent(document, 'click', '.action.like, .action.dislike, .action.star', (e, target) => {
  if (e.button) return;

  if (!target.classList.contains('liked')) {
    const other = target.parentNode.querySelector('.liked');
    if (other) {
      redrawCounter(other, -1);
    }
  }

  const incr = target.classList.contains('liked') ? -1 : 1;

  ajaxPut(target.dataset.action, { incr }).json(redrawCounter(target, incr));
});
