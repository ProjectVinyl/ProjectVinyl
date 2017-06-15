(function() {
  function lookup(sender, popout, action, input, validate) {
    ajax.post(`${action}/lookup`, json => {
      popout.empty();
      for (let i = 0; i < json.content.length; i++) {
        const item = $('<li></li>');
        item.text(`${json.content[i][1]} (#${json.content[i][0]})`);
        item.attr('data-name', json.content[i][1]);
        item.on('mousedown', function() {
          input.val($(this).attr('data-name'));
          sender.removeClass('pop-out-shown');
        });
        popout.append(item);
      }
      sender[json.content.length ? 'addClass' : 'removeClass']('pop-out-shown');
      sender[json.reject ? 'addClass' : 'removeClass']('invalid');
    }, 0, {
      query: input.val(), validate: validate ? 1 : 0
    });
  }
  let autocomplete = null;
  $doc.on('focus', '.auto-lookup:not(.loaded) input', function() {
    const input = $(this);
    const me = input.parent();
    me.addClass('loaded');
    const popout = me.find('.pop-out');
    const action = me.attr('data-action');
    let last_value = null;
    const validate = me.hasClass('validate');
    input.on('blur', () => {
      clearInterval(autocomplete);
      autocomplete = null;
    });
    input.on('focus', e => {
      if (!autocomplete) {
        autocomplete = setInterval(() => {
          const value = input.val();
          if (value != last_value) {
            last_value = value;
            lookup(me, popout, action, input, validate);
          }
        }, 1000);
      }
    });
  });
}());
