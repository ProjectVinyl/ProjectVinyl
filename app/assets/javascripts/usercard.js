(function() {
  var hover_timeout = null;
  function openUsercard(sender, usercard) {
    $('.hovercard.shown').removeClass('shown');
    sender.append(usercard);
    if (hover_timeout) {
      clearTimeout(hover_timeout);
    }
    setTimeout(function() {
      usercard.addClass('shown');
      hover_timeout = setTimeout(function() {
        $('.user-link:not(:hover) .hovercard.shown').removeClass('shown');
      }, 500);
    }, 500);
  }
  
  $doc.on('mouseenter', '.user-link', function() {
    var sender = $(this);
    var id = sender.attr('data-id');
    var usercard = $('.hovercard[data-id=' + id + ']');
    if (!usercard.length) {
      usercard = $('<div class="hovercard" data-id="' + id + '"></div>');
      usercard.on('mouseenter', function(ev) {
        ev.stopPropagation();
      });
      sender.append(usercard);
      ajax.get('artist/hovercard', function(html) {
        usercard.html(html);
        openUsercard(sender, usercard);
      }, {id: id}, 1);
    } else {
      openUsercard(sender, usercard);
    }
  });
  
  $doc.on('mouseleave', '.user-link', function() {
    $('.hovercard.shown').toggleClass('shown');
  });
})();