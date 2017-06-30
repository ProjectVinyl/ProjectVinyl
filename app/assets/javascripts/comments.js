import { ajax } from './ajax.js';
import { paginator } from './paginator.js';
import { error } from './popup.js';
import { scrollTo } from './uiscroll.js';
import { jSlim } from './jslim.js';

// app/views/thread/_comment_box.html.erb
// app/views/thread/_view_reverse.erb
window.postComment = function postComment(sender, threadId, order, reportState) {
  sender = $(sender).parent();
  var input = sender.querySelector('textarea, input.comment-content');
  var comment = input.value.trim();
  if (!comment) return error('You have to type something to post');
  
  var data = {
    thread: threadId,
    order: order,
    comment: comment
  };
  if (reportState) data.report_state = reportState;
  
  sender.classList.add('posting');
  ajax.post('comments/new', function(json) {
    sender.classList.remove('posting');
    paginator.repaint($('#thread-' + threadId).closest('.paginator'), json);
    scrollTo('#comment_' + json.focus);
    input.value = '';
    input.change();
  }, 0, data);
};

// app/views/thread/_comment.html.erb
window.removeComment = function removeComment(id, json) {
  id = document.getElementById('comment_' + id);
  if (id) {
    if (json.content) {
      id.outerHTML += json.content;
      id.parentNode.removeChild(id);
      return;
    }
    id.style.minHeight = 0;
    id.style.height = id.clientHeight;
    id.style.overflow = 'hidden';
    id.style.transition = '0.5s ease all';
    id.style.opacity = 0;
    id.style.height = 0;
    setTimeout(function() {
      id.parentNode.removeChild(id);
    }, 500);
  }
};

function editComment(sender) {
  sender = sender.parentNode;
  ajax.post('comments/edit', function() {
    sender.classList.remove('editing');
  }, 1, {
    id: sender.dataset.id,
    comment: sender.querySelector('textarea, input.comment-content').value
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
  textarea.val('>>' + sender[0].dataset['o-id'] + ' [q]\n' + jSlim.dom.decodeEntities(sender[0].dataset.comment) + '\n[/q]' + textarea.val());
  textarea.change();
}

// app/views/thread/_view_reverse.erb
window.reportState = function reportState(sender) {
  sender = sender.parentNode;
  if (sender.querySelector('input[name=resolve]:checked')) return 'resolve';
  if (sender.querySelector('input[name=close]:checked')) return 'close';
  if (sender.querySelector('input[name=unresolve]:checked')) return 'open';
  return false;
};

jSlim.on(document, 'click', '.comment .mention, .comment .comment-content a[data-link="2"]', function(ev) {
  findComment(this);
  ev.preventDefault();
});

jSlim.on(document, 'click', '.reply-comment', function() {
  replyTo(this);
});

jSlim.on(document, 'click', '.edit-comment-submit', function() {
  editComment(this);
});

jSlim.on(document, 'click', '.spoiler', function() {
  this.classList.toggle('revealed');
});

if (document.location.hash.indexOf('#comment_') == 0) {
  lookupComment(document.location.hash.split('_')[1]);
}
