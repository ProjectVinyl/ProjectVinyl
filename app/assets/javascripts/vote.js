import { ajax } from './ajax.js';

function count(me, offset) {
  var likes = me[0].dataset.count;
  var count = me.find('.count');
  
  if (!likes) {
    likes = 0;
  } else {
    likes = parseInt(likes);
  }
  likes += offset;
  me[0].dataset.count = likes;
  if (likes == 0) {
    count.remove();
  } else {
    if (!count.length) {
      me.children('span').append('<span class="count" >' + likes + '</span>');
    } else {
      count.text(likes);
    }
  }
  
  ajax.post(me[0].dataset.action + '/' + me[0].dataset.id + '/' + offset, function(json) {
    if (count.length) count.text(json.count);
  });
  return me;
}

$(document).on('click', 'button.action.like, button.action.dislike', function() {
  var me = $(this);
  if (me.hasClass('liked')) {
    count(me, -1).removeClass('liked');
  } else {
    var other = me.parent().find('.liked');
    if (other.length) {
      count(other, -1).removeClass('liked');
    }
    count(me, 1).addClass('liked');
  }
});

$(document).on('click', 'button.action.star', function fave() {
  var me = $(this);
  me.toggleClass('starred');
  ajax.post(me[0].dataset.action + '/' + me[0].dataset.id, function(xml) {
    if (xml.added) {
      me.addClass('starred');
    } else {
      me.removeClass('starred');
    }
  });
});
