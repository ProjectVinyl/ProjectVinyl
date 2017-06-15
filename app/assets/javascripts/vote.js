(function() {
  function count(me, offset) {
    let likes = me.attr('data-count');
    if (!likes) {
      likes = 0;
    } else {
      likes = parseInt(likes);
    }
    likes += offset;
    me.attr('data-count', likes);
    if (likes == 0) {
      me.find('.count').remove();
    } else {
      var count = me.find('.count');
      if (!count.length) {
        me.children('span').append(`<span class="count" >${likes}</span>`);
      } else {
        count.text(likes);
      }
    }
    ajax.post(`${me.attr('data-action')}/${me.attr('data-id')}/${offset}`, json => {
      if (count) count.text(json.count);
    });
    return me;
  }

  $doc.on('click', 'button.action.like, button.action.dislike', function() {
    const me = $(this);
    if (me.hasClass('liked')) {
      count(me, -1).removeClass('liked');
    } else {
      const other = me.parent().find('.liked');
      if (other.length) {
        count(other, -1).removeClass('liked');
      }
      count(me, 1).addClass('liked');
    }
  });

  $doc.on('click', 'button.action.star', function fave() {
    const me = $(this);
    me.toggleClass('starred');
    ajax.post(`${me.attr('data-action')}/${me.attr('data-id')}`, xml => {
      if (xml.added) {
        me.addClass('starred');
      } else {
        me.removeClass('starred');
      }
    });
  });
}());
