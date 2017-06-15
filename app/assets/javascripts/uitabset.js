function focusTab(me) {
  if (!me.hasClass('selected') && me.attr('data-target')) {
    const other = me.parent().find('.selected');
    other.removeClass('selected');
    me.addClass('selected');
    $(`div[data-tab="${other.attr('data-target')}"]`).removeClass('selected').trigger('tabblur');
    $(`div[data-tab="${me.attr('data-target')}"]`).addClass('selected').trigger('tabfocus');
  }
}

$doc.on('click', '.tab-set > li.button:not([data-disabled])', function() {
  focusTab($(this));
});

$doc.on('click', '.tab-set > li.button i.fa-close', function(e) {
  const me = $(this).parent();
  $(`div[data-tab="${me.attr('data-target')}"]`).remove();
  me.addClass('hidden');

  setTimeout(() => {
    me.remove();
  }, 25);

  const other = me.parent().find('li.button:not([data-disabled]):not(.hidden)[data-target]').first();
  focusTab(other);

  e.preventDefault();
  e.stopPropagation();
});

$doc.on('click', '.tab-set.async a.button:not([data-disabled])', function(e) {
  const me = $(this);
  if (!me.hasClass('selected')) {
    const parent = me.parent();
    const other = parent.find('.selected');

    other.removeClass('selected');
    me.addClass('selected');

    const holder = $(`.tab[data-tab=${parent.attr('data-target')}]`);
    holder.addClass('waiting');

    ajax.get(parent.attr('data-url'), json => {
      holder.html(json.content);
      holder.removeClass('waiting');
    }, {
      type: me.attr('data-target'), page: me.attr('data-page') || 0
    });
  }
  e.preventDefault();
});
