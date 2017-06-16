$doc.on('focus', 'label input, label select', function() {
  $(this).closest('label').addClass('focus');
});

$doc.on('blur', 'label input, label select', function() {
  $(this).closest('label').removeClass('focus');
});

$doc.on('touchstart', '.drop-down-holder:not(.hover), .mobile-touch-toggle:not(.hover)', function(e) {
  var me = $(this);
  var lis = me.find('a, li');
  
  lis.on('touchstart', function(e) {
    e.stopPropagation();
  });
  
  me.one('touchstart touchmove', clos);
  $doc.one('touchstart touchmove', clos);
  
  me.addClass('hover');
  e.preventDefault();
  e.stopPropagation();
  
  function clos(e) {
    me.off('touchstart touchmove');
    me.removeClass('hover');
    lis.off('touchstart');
    e.preventDefault();
    e.stopPropagation();
  }
});

(function() {
  var win = $(window);
  var Popout = {
    toggle: function(sender) {
      if (sender.length && !sender.hasClass('pop-out-shown')) {
        this.show(sender);
      } else {
        this.hideAll();
      }
    },
    show: function(sender) {
      var left = sender.content.offset().left;
      
      this.hideAll();
      sender.addClass('pop-out-shown');
      sender.removeClass('pop-left');
      sender.removeClass('pop-right');
      
      if (left + sender.content.width() > win.width()) {
        sender.addClass('pop-left');
      }
      if (left < 0) {
        sender.addClass('pop-right');
      }
    },
    hideAll: function() {
      $('.pop-out-shown').removeClass('pop-out-shown');
    }
  };
  
  $doc.on('click', '.pop-out-toggle', function() {
    var me = $(this);
    var popout = me.closest('.popper');
    
    popout.content = popout.find('.pop-out');
    
    me.on('click', function(e) {
      e.stopPropagation();
      e.preventDefault();
      Popout.toggle(popout);
    });
    
    popout.on('mousedown', function(e) {
      e.stopPropagation();
    });
    
    Popout.toggle(popout);
  });
  
  $doc.on('mousedown', function() {
    Popout.hideAll();
  });
})();