import { ajaxDelete } from '../utils/ajax';
import { cookies, DAYS } from '../utils/cookies';
import { repaintPagination } from '../components/paginator';
import { addDelegatedEvent, halt } from '../jslim/events';

addDelegatedEvent(document, 'click', '.removeable .remove', function(e) {
  if (e.button !== 0) return;
  halt(e);

  const me = this.closest('.removeable');

  if (me.dataset.persistentId) {
    const now = Date.now();
    cookies.set('last_dismissal', now);
    cookies.set('dismissed_' + me.dataset.persistentId, now, {
      age: DAYS * 12
    });
  }

  if (me.classList.contains('repaintable')) {
    ajaxDelete(`${me.dataset.target}/${me.dataset.id}`).json(json => repaintPagination(me.closest('.paginator'), json));
    return;
  }

  if (me.dataset.target) {
    ajaxDelete(`${me.dataset.target}/${me.dataset.id}`).text(() => remove(me));
  } else {
    remove(me);
  }
});

function remove(me, recurse) {
  const container = me.parentNode;

  container.removeChild(me);

  if (!recurse) {
    container.dispatchEvent(new CustomEvent('removed', {
      detail: {target: me},
      bubbles: true,
      cancellable: true
    }));
  }

  if (container.classList.contains('group') && !container.querySelector('.removeable, .group')) {
    remove(container, true);
  }
}
