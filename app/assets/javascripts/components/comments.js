import { ajax } from '../utils/ajax.js';
import { paginator } from './paginator.js';
import { error } from './popup.js';
import { scrollTo } from '../ui/scroll.js';
import { decodeEntities } from '../utils/misc.js';

// app/views/thread/_comment_box.html.erb
// app/views/thread/_view_reverse.erb
window.postComment = function postComment(sender, threadId, order, reportState) {
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
};

// app/views/thread/_comment.html.erb
window.removeComment = function removeComment(id, json) {
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
};

function editComment(sender) {
  sender = $(sender).parent();
  ajax.post('comments/edit', function() {
    sender.removeClass('editing');
  }, 1, {
    id: sender[0].dataset.id,
    comment: sender.find('textarea, input.comment-content').val()
  });
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

// app/views/thread/_view_reverse.erb
window.reportState = function reportState(sender) {
  sender = $(sender).parent();
  if (sender.find('input[name=resolve]:checked').length) return 'resolve';
  if (sender.find('input[name=close]:checked').length) return 'close';
  if (sender.find('input[name=unresolve]:checked').length) return 'open';
  return false;
};

$(document).on('click', '.comment .mention, .comment .comment-content a[data-link="2"]', function(ev) {
  findComment(this);
  ev.preventDefault();
});

$(document).on('click', '.reply-comment', function() {
  replyTo(this);
});

$(document).on('click', '.edit-comment-submit', function() {
  editComment(this);
});

$(document).on('click', '.spoiler', function() {
  $(this).toggleClass('revealed');
});

if (document.location.hash.indexOf('#comment_') == 0) {
  lookupComment(document.location.hash.split('_')[1]);
}
