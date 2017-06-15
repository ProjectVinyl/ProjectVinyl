(function() {
  function toggle(sender) {
    var id = sender.attr('data-id');

    var action = sender.attr('data-target') + '/' + sender.attr('data-action');

    var data = sender.attr('data-with');
    if (data) action += '?extra=' + $(data).val();

    var check_icon = sender.attr('data-checked-icon') || 'check';
    var uncheck_icon = sender.attr('data-unchecked-icon');

    var state = sender.attr('data-state');

    ajax.post(action, function(json) {
      var family = sender.attr('data-family');
      if (family) {
        $('.action.toggle[data-family="' + family + '"][data-id="' + id + '"]').each(function() {
          var me = $(this);
          var uncheck = me.attr('data-unchecked-icon');
          var check = me.attr('data-checked-icon') || 'check';
          me.find('.icon').html(json[$(this).attr('data-descriminator')] ? '<i class="fa fa-' + check + '"></i>' : uncheck ? '<i class="fa fa-' + uncheck + '"></i>' : '');
        });
      } else {
        sender.find('.icon').html(json.added ? '<i class="fa fa-' + check_icon + '"></i>' : uncheck_icon ? '<i class="fa fa-' + uncheck_icon + '"></i>' : '');
        if (state) {
          sender.parents(sender.attr('data-parent'))[json.added ? 'addClass' : 'removeClass'](state);
        }
      }
    }, false, {
      id: id, item: sender.attr('data-item')
    });
  }

  $doc.on('click', '.action.toggle', function(e) {
    toggle($(this));
  });

  $doc.on('click', '.state-toggle', function(ev) {
    ev.preventDefault();
    var me = $(this);
    var state = me.attr('data-state');
    var parent = me.attr('data-parent');
    parent = parent ? me.closest(parent) : me.parent();
    parent.toggleClass(state);
    me.text(me.attr('data-' + parent.hasClass(state)));
    me.trigger('toggle');
  });
})();