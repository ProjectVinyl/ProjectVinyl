import { ajax } from '../utils/ajax';
import { repaintPagination } from '../components/paginator';
import { addDelegatedEvent, halt } from '../jslim/events';

addDelegatedEvent(document, 'click', '.removeable .remove', function(e) {
  if (e.button !== 0) return;
  halt(e);

  const me = this.closest('.removeable');

  if (me.classList.contains('repaintable')) {
    ajax.delete(`${me.dataset.target}/${me.dataset.id}`).json(json => repaintPagination(me.closest('.paginator'), json));
    return;
  }

  if (me.dataset.target) {
    ajax.delete(`${me.dataset.target}/${me.dataset.id}`).json(() => remove(me));
  } else {
    remove(me);
  }
});

function remove(me) {
  const container = me.parentNode;

  container.removeChild(me);
  
  if (container.classList.contains('group') && !container.querySelector('.removeable, .group')) {
    remove(container);
  }
}