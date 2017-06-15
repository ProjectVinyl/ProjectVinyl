$doc.on('mousedown', function() {
  $('.pop-out-shown').removeClass('pop-out-shown');
});

$doc.on('focus', 'label input, label select', function() {
  $(this).closest('label').addClass('focus');
});

$doc.on('blur', 'label input, label select', function() {
  $(this).closest('label').removeClass('focus');
});

$doc.on('touchstart', '.drop-down-holder:not(.hover), .mobile-touch-toggle:not(.hover)', function(e) {
  var me = $(this);
  me.addClass('hover');
  e.preventDefault();
  e.stopPropagation();
  var lis = me.find('a, li');
  lis.on('touchstart', function(e) {
    e.stopPropagation();
  });
  function clos(e) {
    me.off('touchstart touchmove');
    me.removeClass('hover');
    lis.off('touchstart');
    e.preventDefault();
    e.stopPropagation();
  }
  me.one('touchstart touchmove', clos);
  $(document).one('touchstart touchmove', clos);
});

$doc.on('click', '.pop-out-toggle', function() {
  var me = $(this);
  var popout = $(this).closest('.popper');
  var popoutcontent = popout.find('.pop-out');
  me.on('click', function(e) {
    if (popout.length && !popout.hasClass('pop-out-shown')) {
      $('.pop-out-shown').removeClass('pop-out-shown');
      popout.addClass('pop-out-shown');
      popout.removeClass('pop-left');
      popout.removeClass('pop-right');
      
      var left = popoutcontent.offset().left;
      var right = left + popoutcontent.width();
      var width = $(window).width();
      
      if (right > width) {
        popout.addClass('pop-left');
      }
      if (left < 0 ) {
        popout.addClass('pop-right');
      }
    } else {
      $('.pop-out-shown').removeClass('pop-out-shown');
    }
    e.stopPropagation();
    e.preventDefault();
  });
  popout.on('mousedown', function(e) {
    e.stopPropagation();
  });
  me.click();
});