import { addDelegatedEvent } from '../jslim/events';
import { ajax } from '../utils/ajax';

function count(me, offset, save) {
  me.classList.toggle('liked', offset > 0);
  
  let count = me.querySelector('.count');
  if (!count) {
    count = me.querySelector('span');
    count.innerHTML = '<span class="count"></span>';
    count = count.firstChild;
  }
  
  const updateUI = state => {
    me.dataset.count = state.count;
    count.classList.toggle('hidden', state.count < 1);
    count.innerText = state.count;
  };
  
  updateUI({ count: (parseInt(me.dataset.count) || 0) + offset });
  
  return updateUI;
}

function save(sender, data) {
  return ajax.put(`${sender.dataset.target || 'videos'}/${sender.dataset.id}/${sender.dataset.action}`, data);
}

addDelegatedEvent(document, 'click', 'button.action.like, button.action.dislike', (e, target) => {
  if (e.button) return;
  if (!target.classList.contains('liked')) {
    let other = target.parentNode.querySelector('.liked');
    if (other) count(other, -1);
  }
  const offset = target.classList.contains('liked') ? -1 : 1;
  save(target, {
    incr: offset
  }).json(count(target, offset));
});

addDelegatedEvent(document, 'click', 'button.action.star', (e, target) => {
  if (e.button) return;
  target.classList.toggle('starred');
  save(target).json(json => {
    target.classList.toggle('starred', json.count);
  });
});
