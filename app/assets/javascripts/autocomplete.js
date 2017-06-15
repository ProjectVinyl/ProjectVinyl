(function() {
  function lookup(sender, popout, action, input, validate) {
    ajax.post(action + '/lookup', function(json) {
      popout.empty();
      for (var i = 0; i < json.content.length; i++) {
        var item = $('<li></li>');
        item.text(json.content[i][1] + ' (#' + json.content[i][0] + ')');
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
  var autocomplete = null;
  $doc.on('focus', '.auto-lookup:not(.loaded) input', function() {
    var input = $(this);
    var me = input.parent();
    me.addClass('loaded');
    var popout = me.find('.pop-out');
    var action = me.attr('data-action');
    var last_value = null;
    var validate = me.hasClass('validate');
    input.on('blur', function() {
      clearInterval(autocomplete);
      autocomplete = null;
    });
    input.on('focus', function(e) {
      if (!autocomplete) {
        autocomplete = setInterval(function() {
          var value = input.val();
          if (value != last_value) {
            last_value = value;
            lookup(me, popout, action, input, validate);
          }
        }, 1000);
      }
    });
  });
})();