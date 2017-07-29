import { ajax } from '../utils/ajax';
import { paginator } from '../components/paginator';
import { jSlim } from '../utils/jslim';

jSlim.on(document, 'click', '.removeable .remove', function(e) {
  var me = this.closest('.removeable');
  
  if (me.classList.contains('repaintable')) {
    return ajax.delete(me.dataset.target + '/' + me.dataset.id).json(function(json) {
      paginator.repaint(me.closest('.paginator'), json);
    });
  }
  
  if (me.dataset.target) {
    ajax.post('delete/' + me.dataset.target, {
      id: me.dataset.id
    }).text(function() {
      me.parentNode.removeChild(me);
    });
  } else {
    me.parentNode.removeChild(me);
  }
  e.preventDefault();
  e.stopPropagation();
});
