(function() {
  function toggle(sender) {
    const id = sender.attr('data-id');

    let action = `${sender.attr('data-target')}/${sender.attr('data-action')}`;

    const data = sender.attr('data-with');
    if (data) action += `?extra=${$(data).val()}`;

    const check_icon = sender.attr('data-checked-icon') || 'check';
    const uncheck_icon = sender.attr('data-unchecked-icon');

    const state = sender.attr('data-state');

    ajax.post(action, json => {
      const family = sender.attr('data-family');
      if (family) {
        $(`.action.toggle[data-family="${family}"][data-id="${id}"]`).each(function() {
          const me = $(this);
          const uncheck = me.attr('data-unchecked-icon');
          const check = me.attr('data-checked-icon') || 'check';
          me.find('.icon').html(json[$(this).attr('data-descriminator')] ? `<i class="fa fa-${check}"></i>` : uncheck ? `<i class="fa fa-${uncheck}"></i>` : '');
        });
      } else {
        sender.find('.icon').html(json.added ? `<i class="fa fa-${check_icon}"></i>` : uncheck_icon ? `<i class="fa fa-${uncheck_icon}"></i>` : '');
        if (state) {
          sender.parents(sender.attr('data-parent'))[json.added ? 'addClass' : 'removeClass'](state);
        }
      }
    }, false, {
      id, item: sender.attr('data-item')
    });
  }

  $doc.on('click', '.action.toggle', function(e) {
    toggle($(this));
  });

  $doc.on('click', '.state-toggle', function(ev) {
    ev.preventDefault();
    const me = $(this);
    const state = me.attr('data-state');
    let parent = me.attr('data-parent');
    parent = parent ? me.closest(parent) : me.parent();
    parent.toggleClass(state);
    me.text(me.attr(`data-${parent.hasClass(state)}`));
    me.trigger('toggle');
  });
}());
