function postComment(sender, threadId, order, reportState) {
  sender = $(sender).parent();
  var input = sender.find('textarea, input.comment-content');
  var comment = input.val().trim();
  if (!comment.length) return error('You have to type something to post');
  
  var data = {
    thread: threadId,
    order: order,
    comment: comment
  };
  if (reportState) data.report_state = reportState;
  
  sender.addClass('posting');
  ajax.post('comments/new', function(json) {
    sender.removeClass('posting');
    paginator.repaint($('#thread-' + threadId).closest('.paginator'), json);
    scrollTo('#comment_' + json.focus);
    input.val('').change();
  }, 0, data);
}

function editComment(sender) {
  sender = $(sender).parent();
  ajax.post('comments/edit', function() {
    sender.removeClass('editing');
  }, 1, {
    id: sender[0].dataset.id,
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

function lookupComment(commentId) {
  var comment = $('#comment_' + commentId);
  if (comment.length) {
    return scrollTo(comment).addClass('highlight');
  }
  var pagination = $('.comments').parent();
  ajax.get(pagination[0].dataset.type + '?comment=' + commentId + '&' + pagination[0].dataset.args, function(json) {
    paginator.repaint(pagination, json);
    scrollTo($('#comment_' + commentId)).addClass('highlight');
  });
}

function findComment(sender) {
  sender = $(sender);
  var container = sender.parents('comment');
  var parent = sender.attr('href');
  if ($(parent).length) {
    parent = $(parent);
    if (parent.hasClass('inline')) {
      container.parent().prepend(parent);
    }
    $('.comment.highlight').removeClass('highlight');
    return scrollTo(parent).addClass('highlight');
  }
  
  ajax.get('comments/get', function(html) {
    container.parent().prepend(html);
    $('.comment.highlight').removeClass('highlight');
    parent = scrollTo(parent);
    if (parent) parent.addClass('highlight').addClass('inline');
  }, {
    id: sender[0].dataset.id || parseInt(parent.split('_')[1], 36)
  }, 1);
}

function replyTo(sender) {
  sender = $(sender).parent();
  textarea = sender.closest('.page, body').find('.post-box textarea');
  textarea.focus();
  textarea.val('>>' + sender[0].dataset['o-id'] + ' [q]\n' + decodeEntities(sender[0].dataset.comment) + '\n[/q]' + textarea.val());
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
  if (checks.length) {
    ajax.post('/messages/action', function(json) {
      if (json.content) {
        action.callback(checks, json);
      } else {
        checks.parents('li.thread').each(action.callback);
      }
    }, false, {
      ids: collect(checks, function() {
        return this.value;
      }).join(';'), op: action.id
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

if (document.location.hash.indexOf('#comment_') == 0) {
  lookupComment(document.location.hash.split('_')[1]);
}