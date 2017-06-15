(function() {
  function init(me) {
    me.addClass('loaded');
    var action = me.attr('data-action');
    var url = me.attr('data-url');
    var id = me.attr('data-id');
    var callback = me.attr('data-callback');
    var max_width = me.attr('data-max-width');
    var popup;
    if (action == 'delete' || action == 'remove') {
      if (!popup) {
        popup = new Popup(me.attr('data-title'), me.attr('data-icon'), function() {
          this.content.append('<div class="message_content"></div><div class="foot"></div>');
          this.content.message_content = this.content.find('.message_content');
          var msg = me.attr('data-msg');
          if (msg) {
            this.content.message_content.text(msg);
            this.content.message_content.append('<br/><br/>');
          }
          this.content.message_content.append('Are you sure you want to continue?');

          var ok = $('<button class="button-fw green confirm">Yes</button>');
          var cancel = $('<button class="cancel button-fw blue" style="margin-left:20px;" type="button">No</button>');
          ok.on('click', function() {
            ajax.post(url, function(json) {
              if (action == 'remove') {
                var removeable = me.parents('.removeable');
                if (removeable.hasClass('repaintable')) {
                  paginator.repaint(removeable.closest('.paginator'), json);
                } else {
                  removeable.remove();
                }
              } else {
                if (json.ref) {
                  document.location.replace(json.ref);
                } else if (callback) {
                  window[callback](id, json);
                }
              }
            });
            popup.close();
          });
          cancel.on('click', function() {
            popup.close();
          });
          this.content.foot = this.content.find('.foot');
          this.content.foot.addClass('center');
          this.content.foot.append(ok);
          this.content.foot.append(cancel);
          this.setPersistent();
          this.setWidth(400);
          this.show();
        });
      } else {
        popup.show();
      }
    } else if (action == 'secure') {
      popup = Popup.iframe(url, me.attr('data-title'), me.attr('data-icon'), me.hasClass('confirm-button-thin'), me.attr('data-event-loaded'));
      popup.setPersistent();
    } else {
      popup = Popup.fetch(url, me.attr('data-title'), me.attr('data-icon'), me.hasClass('confirm-button-thin'), me.attr('data-event-loaded'));
      popup.setPersistent();
    }
    if (popup && max_width) popup.content.css('max-width', max_width);
    me.on('click', function(e) {
      popup.show();
      e.preventDefault();
    });
  }

  $doc.on('click', '.confirm-button:not(.loaded)', function(e) {
    init($(this));
    e.preventDefault();
  });
})();