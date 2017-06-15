function postComment(sender, thread_id, order, report_state) {
  sender = $(sender).parent();
  var input = sender.find('textarea, input.comment-content');
  var comment = input.val();
  if (!comment.length) {
    return error('You have to type something to post');
  }
  sender.addClass('posting');
  var data = {
    thread: thread_id,
    order: order,
    comment: comment
  };
  if (report_state) data.report_state = report_state;
  ajax.post('comments/new', function(json) {
    sender.removeClass('posting');
    paginator.repaint($('#thread-' + thread_id).closest('.paginator'), json);
    scrollTo('#comment_' + json.focus);
    input.val('').change();
  }, 0, data);
}

function editComment(sender) {
  sender = $(sender).parent();
  ajax.post('comments/edit', function(html) {
    sender.removeClass('editing');
  }, 1, {
    id: sender.attr('data-id'),
    comment: sender.find('textarea, input.comment-content').val()
  });
}

function removeComment(id, json) {
  id = $('#comment_' + id);
  if (json.content) {
    return id.after(json.content).remove();
  }
  if (id.length) {
    id.css({
      'min-height': 0,
      height: id.height(), overflow: 'hidden'
    }).css('transition', '0.5s ease all').css({
      opacity: 0, height: 0
    });
    setTimeout(function() {
      id.remove();
    }, 500);
  }
}

function lookupComment(comment_id) {
  var comment = $('#comment_' + comment_id);
  if (comment.length) {
    scrollTo(comment).addClass('highlight');
  } else {
    var pagination = $('.comments').parent();
    ajax.get(pagination.attr('data-type') + '?comment=' + comment_id + '&' + pagination.attr('data-args'), function(json) {
      paginator.repaint(pagination, json);
      scrollTo($('#comment_' + comment_id)).addClass('highlight');
    });
  }
}

function findComment(sender) {
  sender = $(sender);
  var container = sender.parents('comment');
  var parent = sender.attr('href');
  if (!$(parent).length) {
    ajax.get('comments/get', function(html) {
      container.parent().prepend(html);
      $('.comment.highlight').removeClass('highlight');
      if (parent = scrollTo(parent)) parent.addClass('highlight').addClass('inline');
    }, {
      id: sender.attr('data-comment-id') || parseInt(parent.split('_')[1], 36)
    }, 1);
  } else {
    parent = $(parent);
    if (parent.hasClass('inline')) {
      container.parent().prepend(parent);
    }
    $('.comment.highlight').removeClass('highlight');
    scrollTo(parent).addClass('highlight');
  }
}

function replyTo(sender) {
  sender = $(sender).parent();
  textarea = sender.closest('.page, body').find('.post-box textarea');
  textarea.focus();
  textarea.val('>>' + sender.attr('data-o-id') + ' [q]\n' + decode_entities(sender.attr('data-comment')) + '\n[/q]' + textarea.val());
  textarea.change();
}

function markRead() {
  messageOperation({
    id: 'read', callback: function() {
      var me = $(this);
      me.removeClass('unread');
      me.find('button.button-bub.toggle i').attr('class', 'fa fa-star-o');
    }
  });
}

function markUnRead() {
  messageOperation({
    id: 'unread', callback: function() {
      var me = $(this);
      me.addClass('unread');
      me.find('button.button-bub.toggle i').attr('class', 'fa fa-star');
    }
  });
}

function markDeleted() {
  messageOperation({
    id: 'delete', callback: function(me, json) {
      paginator.repaint(me.closest('.paginator'), json);
    }
  });
}

function messageOperation(action) {
  var checks = $('input.message_select:checked');
  if (checks.length > 0) {
    var ids = [];
    checks.each(function() {
      ids.push(this.value);
    });
    ajax.post('/messages/action', function(json) {
      if (json.content) {
        action.callback(checks, json);
      } else {
        checks.parents('li.thread').each(action.callback);
      }
    }, false, {
      ids: ids.join(';'), op: action.id
    });
  }
}

$doc.on('click', '.reply-comment', function() {
  replyTo(this);
});

$doc.on('click', '.edit-comment-submit', function() {
  editComment(this);
});

$doc.on('click', '.comment .mention, .comment .comment-content a[data-link="2"]', function(ev) {
  findComment(this);
  ev.preventDefault();
});

$doc.on('click', '.spoiler', function() {
  $(this).toggleClass('revealed');
});