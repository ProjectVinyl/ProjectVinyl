import { addDelegatedEvent } from '../jslim/events';
import { ajaxPut } from '../utils/ajax';
import { formatNumber, MAX_DISPLAYED_VALUE } from '../utils/numbers';

function count(me, offset, save) {
  me.classList.toggle('liked', offset > 0);
  
  const count = me.querySelector('.count');

  const updateUI = state => {
    me.dataset.count = state.count;
    if (count) {
      count.innerText = formatNumber(state.count, MAX_DISPLAYED_VALUE);
    }

    const score = me.parentNode.querySelector('.score');

    if (score) {
      const likes = parseInt(me.parentNode.querySelector('.like').dataset.count);
      const dislikes = parseInt(me.parentNode.querySelector('.dislike').dataset.count);
      score.innerHTML = `<b>${formatNumber(likes - dislikes, MAX_DISPLAYED_VALUE)}</b>`;
    }
    
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
  };
  
  updateUI({ count: (parseInt(me.dataset.count) || 0) + offset });
  
  return updateUI;
}

function save(sender, data) {
  return ajaxPut(sender.dataset.action, data);
}

addDelegatedEvent(document, 'click', '.action.like, .action.dislike, .action.star', (e, target) => {
  if (e.button) {
    return;
  }
  if (!target.classList.contains('liked')) {
    let other = target.parentNode.querySelector('.liked');
    if (other) {
      count(other, -1);
    }
  }

  const offset = target.classList.contains('liked') ? -1 : 1;

  save(target, {
    incr: offset
  }).json(count(target, offset));
});
