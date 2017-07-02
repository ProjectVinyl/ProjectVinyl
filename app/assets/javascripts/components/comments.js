import { ajax } from '../utils/ajax.js';
import { paginator } from './paginator.js';
import { error } from './popup.js';
import { scrollTo } from '../ui/scroll.js';
import { jSlim } from '../utils/jslim.js';

// app/views/thread/_comment_box.html.erb
// app/views/thread/_view_reverse.erb
window.postComment = function postComment(sender, threadId, order, reportState) {
  sender = sender.parentNode;
  let input = sender.querySelector('textarea, input.comment-content');
  let comment = input.value.trim();
  if (!comment) return error('You have to type something to post');
  
  var data = {
    thread: threadId,
    order: order,
    comment: comment
  };
  if (reportState) data.report_state = reportState;
  
  sender.classList.add('posting');
  ajax.post('comments/new', data).json(function(json) {
    sender.classList.remove('posting');
    paginator.repaint(document.getElementById('#thread-' + threadId).closest('.paginator'), json);
    scrollTo(document.querySelector('#comment_' + json.focus));
    input.value = '';
    input.change();
  });
};

// app/views/thread/_comment.html.erb
window.removeComment = function removeComment(id, json) {
  var el = document.getElementById('comment_' + id);
  if (!el) return;
  
  if (json.content) {
    el.insertAdjacentHTML('afterend', json.content);
    el.parentNode.removeChild(el);
    return;
  }
  el.style.minHeight = '0';
  el.style.height = el.offsetHeight;
  el.style.overflow = 'hidden';
  el.style.transition = '0.5s ease all';
  
  // Fade out (FIXME: do this in CSS)
  requestAnimationFrame(function() {
    el.style.opacity = '0';
    el.style.height = '0';
  });
  
  setTimeout(function() {
    el.parentNode.removeChild(el);
  }, 500);
};

function scrollToAndHighlightElement(comment) {
  if (comment) {
    scrollTo(comment);
    comment.classList.add('highlight');
    return true;
  }
}

function scrollToAndHighlight(commentId) {
  return scrollToAndHighlightElement(document.getElementById('comment_' + commentId));
}

function lookupComment(commentId) {
  if (scrollToAndHighlight(commentId)) return;
  
  var pagination = document.querySelector('.comments').parentNode;
  ajax.get(pagination.dataset.type, 'comment=' + commentId + '&' + pagination.dataset.args).json(function(json) {
    paginator.repaint(pagination, json);
    scrollToAndHighlight(commentId);
  });
}

function editComment(sender) {
  sender = sender.parentNode;
  ajax.post('comments/edit', {
    id: sender.dataset.id,
    comment: sender.querySelector('textarea, input.comment-content').value
  }, function() {
    sender.classList.remove('editing');
  });
}

function findComment(sender) {
  var container = sender.closest('comment');
  var parent = sender.href;
  var parentEl = document.querySelector(parent);
  // This is begging for a refactor.
  if (parentEl) {
    if (parentEl.classList.contains('inline')) {
      // Prepend
      container.parentNode.insertBefore(parentEl, container.parentNode.firstChild);
    }
    jSlim.all('.comment.highlight', function() {
      this.classList.remove('highlight');
    });
    return scrollToAndHighlightElement(parentEl);
  }
  
  ajax.get('comment/get', function(html) {
    container.parentNode.insertAdjacentHTML('afterbegin', html);
    parentEl = scrollTo(parent);
    if (parentEl) {
      parentEl.classList.add('highlight');
      parentEl.classList.add('inline');
    }
  }, {
    id: sender.dataset.id || parseInt(parent.split('_')[1], 36)
  }, 1);
}

function replyTo(sender) {
  sender = sender.parentNode;
  var textarea = sender.closest('.page, body').querySelector('.post-box textarea');
  textarea.value = '>>' + sender.dataset.oId + ' [q]\n' + jSlim.dom.decodeEntities(sender.dataset.comment) + '\n[/q]' + textarea.value;
  textarea.focus();
}

// app/views/thread/_view_reverse.erb
window.reportState = function reportState(sender) {
  sender = sender.parentNode;
  if (sender.querySelector('input[name="resolve"]:checked')) return 'resolve';
  if (sender.querySelector('input[name="close"]:checked')) return 'close';
  if (sender.querySelector('input[name="unresolve"]:checked')) return 'open';
  return false;
};

function revealSpoiler(target) {
  target.classList.toggle('revealed');
}

var targets = {
  '.comment .mention, .comment .comment-content a[data-link="2"]': findComment,
  '.reply-comment': replyTo,
  '.edit-comment-submit': editComment,
  '.spoiler': revealSpoiler
};

jSlim.ready(function() {
  document.addEventListener('click', function(event) {
    // Left-click only
    if (event.which !== 1 && event.button !== 0) return;
    
    for (const target in targets) {
      var el = event.target.closest(target);
      if (el) {
        event.preventDefault();
        return targets[target](el);
      }
    }
  });
  
  if (document.location.hash.indexOf('#comment_') == 0) {
    lookupComment(document.location.hash.split('_')[1]);
  }
});
