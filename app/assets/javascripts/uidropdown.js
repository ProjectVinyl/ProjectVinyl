$doc.on('mousedown', () => {
  $('.pop-out-shown').removeClass('pop-out-shown');
});

$doc.on('focus', 'label input, label select', function() {
  $(this).closest('label').addClass('focus');
});

$doc.on('blur', 'label input, label select', function() {
  $(this).closest('label').removeClass('focus');
});

$doc.on('touchstart', '.drop-down-holder:not(.hover), .mobile-touch-toggle:not(.hover)', function(e) {
  const me = $(this);
  me.addClass('hover');
  e.preventDefault();
  e.stopPropagation();
  const lis = me.find('a, li');
  lis.on('touchstart', e => {
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
  const me = $(this);
  const popout = $(this).closest('.popper');
  const popoutcontent = popout.find('.pop-out');
  me.on('click', e => {
    if (popout.length && !popout.hasClass('pop-out-shown')) {
      $('.pop-out-shown').removeClass('pop-out-shown');
      popout.addClass('pop-out-shown');
      popout.removeClass('pop-left');
      popout.removeClass('pop-right');

      const left = popoutcontent.offset().left;
      const right = left + popoutcontent.width();
      const width = $(window).width();

      if (right > width) {
        popout.addClass('pop-left');
      }
      if (left < 0) {
        popout.addClass('pop-right');
      }
    } else {
      $('.pop-out-shown').removeClass('pop-out-shown');
    }
    e.stopPropagation();
    e.preventDefault();
  });
  popout.on('mousedown', e => {
    e.stopPropagation();
  });
  me.click();
});
