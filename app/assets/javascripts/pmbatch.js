import { ajax } from './ajax.js';
import { paginator } from './paginator.js';

(function() {
  window.markRead = function markRead() {
    messageOperation({
      id: 'read', callback: function() {
        var me = $(this);
        me.removeClass('unread');
        me.find('button.button-bub.toggle i').attr('class', 'fa fa-star-o');
      }
    });
  }
  
  window.markUnRead = function markUnRead() {
    messageOperation({
      id: 'unread', callback: function() {
        var me = $(this);
        me.addClass('unread');
        me.find('button.button-bub.toggle i').attr('class', 'fa fa-star');
      }
    });
  };
  
  window.markDeleted = function markDeleted() {
    messageOperation({
      id: 'delete', callback: function(me, json) {
        paginator.repaint(me.closest('.paginator'), json);
      }
    });
  };
  
  function messageOperation(action) {
    var checks = $('input.message_select:checked');
    if (checks.length) {
      ajax.post('/messages/' + action, function(json) {
        if (json.content) {
          action.callback.call(checks, json);
        } else {
          checks.parents('li.thread').each(action.callback);
        }
      }, false, {
        ids: checks.map(c => c.value).join(';'),
        op: action.id
      });
    }
  }
})();
