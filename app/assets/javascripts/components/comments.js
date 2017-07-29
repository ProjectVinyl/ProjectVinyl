import { ajax } from '../utils/ajax';
import { paginator } from './paginator';
import { popupError } from './popup';
import { scrollTo } from '../ui/scroll';
import { jSlim } from '../utils/jslim';

function postComment(sender) {
  var threadId = sender.dataset.threadId;
  var order = sender.dataset.order;
  
  sender = sender.parentNode;
  let input = sender.querySelector('textarea, input.comment-content');
  let comment = input.value.trim();
  if (!comment) return popupError('You have to type something to post');
  
  var data = {
    thread: threadId,
    order: order,
    comment: comment
  };
  if (sender.classList.contains('report-state')) data.report_state = reportState(sender);
  
  sender.classList.add('posting');
  ajax.post('comments', data).json(function(json) {
    sender.classList.remove('posting');
    paginator.repaint(document.getElementById('thread-' + threadId).closest('.paginator'), json);
    scrollTo(document.querySelector('#comment_' + json.focus));
    input.value = '';
  });
}

function removeComment(el, json) {
  if (!el) return;
  
  el.style.height = el.offsetHeight + 'px';
  requestAnimationFrame(function() {
    el.classList.add('hidden');
    if (json.content) {
      el.insertAdjacentHTML('afterend', json.content);
      el.nextSibling.style.height = el.nextSibling.offsetHeight + 'px';
      el.nextSibling.classList.add('hidden');
      requestAnimationFrame(function() {
        el.nextSibling.classList.remove('hidden');
      });
    }
    setTimeout(function() {
      el.parentNode.removeChild(el);
    }, 500);
  });
};

jSlim.on(document, 'fetch:complete', '.js-remove-comment', function(event) {
  removeComment(this.closest('.comment'), event.detail.data);
});

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
  ajax.patch('comments/' + sender.dataset.id, {
    comment: sender.querySelector('textarea, input.comment-content').value
  }).text(function() {
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
  
  ajax.get('find/comments', {
    id: sender.dataset.id || parseInt(parent.split('_')[1], 36)
  }).text(function(html) {
    container.parentNode.insertAdjacentHTML('afterbegin', html);
    scrollTo(parentEl);
    if (parentEl) {
      parentEl.classList.add('highlight');
      parentEl.classList.add('inline');
    }
  });
}

function replyTo(sender) {
  sender = sender.parentNode;
  var textarea = sender.closest('.page, body').querySelector('.post-box textarea');
  textarea.value = '>>' + sender.dataset.oId + ' [q]\n' + jSlim.dom.decodeEntities(sender.dataset.comment) + '\n[/q]' + textarea.value;
  textarea.focus();
}

function reportState(sender) {
  sender = sender.parentNode;
  if (sender.querySelector('input[name="resolve"]:checked')) return 'resolve';
  if (sender.querySelector('input[name="close"]:checked')) return 'close';
  if (sender.querySelector('input[name="unresolve"]:checked')) return 'open';
  return false;
}

function revealSpoiler(target) {
  target.classList.toggle('revealed');
}

var targets = {
  'button.post-submitter': postComment,
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
