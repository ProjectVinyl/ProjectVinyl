$(document).on('focus', 'label input, label select', function() {
  $(this).closest('label').addClass('focus');
});

$(document).on('blur', 'label input, label select', function() {
  $(this).closest('label').removeClass('focus');
});

$(document).on('touchstart', '.drop-down-holder:not(.hover), .mobile-touch-toggle:not(.hover)', function(e) {
  var me = $(this);
  var lis = me.find('a, li');
  
  lis.on('touchstart', function(e) {
    e.stopPropagation();
  });
  
  me.one('touchstart touchmove', clos);
  $(document).one('touchstart touchmove', clos);
  
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

const Popout = {
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
    
    if (left + sender.content.width() > $(window).width()) {
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

$(document).on('click', '.pop-out-toggle', function() {
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

$(document).on('mousedown', function() {
  Popout.hideAll();
});
