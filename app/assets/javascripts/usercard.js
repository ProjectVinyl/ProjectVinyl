(function() {
  let hover_timeout = null;
  function openUsercard(sender, usercard) {
    $('.hovercard.shown').removeClass('shown');
    sender.append(usercard);
    if (hover_timeout) {
      clearTimeout(hover_timeout);
    }
    setTimeout(() => {
      usercard.addClass('shown');
      hover_timeout = setTimeout(() => {
        $('.user-link:not(:hover) .hovercard.shown').removeClass('shown');
      }, 500);
    }, 500);
  }

  $doc.on('mouseenter', '.user-link', function() {
    const sender = $(this);
    const id = sender.attr('data-id');
    let usercard = $(`.hovercard[data-id=${id}]`);
    if (!usercard.length) {
      usercard = $(`<div class="hovercard" data-id="${id}"></div>`);
      usercard.on('mouseenter', ev => {
        ev.stopPropagation();
      });
      sender.append(usercard);
      ajax.get('artist/hovercard', html => {
        usercard.html(html);
        openUsercard(sender, usercard);
      }, {id}, 1);
    } else {
      openUsercard(sender, usercard);
    }
  });

  $doc.on('mouseleave', '.user-link', () => {
    $('.hovercard.shown').toggleClass('shown');
  });
}());
