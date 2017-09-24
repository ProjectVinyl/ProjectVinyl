import { ajax } from '../utils/ajax';
import { repaintPagination } from '../components/paginator';
import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', '.removeable .remove', function(e) {
  if (e.button !== 0) return;
  
  const me = this.closest('.removeable');
  
  if (me.classList.contains('repaintable')) {
    return ajax.delete(`${me.dataset.target}/${me.dataset.id}`).json(json => repaintPagination(me.closest('.paginator'), json));
  }
  
  if (me.dataset.target) {
    ajax.delete(`${me.dataset.target}/${me.dataset.id}`).json(() => me.parentNode.removeChild(me));
  } else {
    me.parentNode.removeChild(me);
  }
  
  e.preventDefault();
  e.stopPropagation();
});
