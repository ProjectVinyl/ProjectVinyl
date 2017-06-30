import { ajax } from '../utils/ajax.js';

function toggle(sender) {
  var id = sender.dataset.id;
  var action = sender.dataset.target + '/' + sender.dataset.action;
  var data = sender.dataset.with;
  var checkIcon = sender.dataset.checkedIcon || 'check';
  var uncheckIcon = sender.dataset.uncheckedIcon;
  var state = sender.dataset.state;
  
  if (data) action += '?extra=' + $(data).val();
  
  ajax.post(action, {
    id: id, item: sender.dataset.item
  }).json(function(json) {
    var family = sender.dataset.family;
    if (family) {
      return $('.action.toggle[data-family="' + family + '"][data-id="' + id + '"]').each(function() {
        var uncheck = this.dataset.uncheckedIcon;
        var check = this.dataset.checkedIcon || 'check';
        $(this).find('.icon').html(json[this.dataset.descriminator] ? '<i class="fa fa-' + check + '"></i>' : uncheck ? '<i class="fa fa-' + uncheck + '"></i>' : '');
      });
    }
    
    $(sender).find('.icon').html(json.added ? '<i class="fa fa-' + checkIcon + '"></i>' : uncheckIcon ? '<i class="fa fa-' + uncheckIcon + '"></i>' : '');
    if (state) {
      $(sender).parents(sender.dataset.parent)[json.added ? 'addClass' : 'removeClass'](state);
    }
  });
}

$(document).on('click', '.action.toggle', function() {
  toggle(this);
});

$(document).on('click', '.state-toggle', function(ev) {
  var state = this.dataset.state;
  var parent = this.dataset.parent;
  var me = $(this);
  
  parent = parent ? me.closest(parent) : me.parent();
  parent.toggleClass(state);
  me.text(this.dataset[parent.hasClass(state)]);
  me.trigger('toggle');
  
  ev.preventDefault();
});
