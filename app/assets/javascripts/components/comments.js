import { ajax } from '../utils/ajax';
import { paginator } from './paginator';
import { popupConfirm, popupError } from './popup';
import { scrollTo } from '../ui/scroll';
import { jSlim } from '../utils/jslim';
import { insertTags } from '../ui/editable';

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

function removeComment(sender) {
  popupConfirm("Are you sure you want to continue?", sender.dataset.title).setOnAccept(function() {
    ajax.delete(sender.getAttribute('href')).json(function(json) {
      var el = sender.closest('.comment')
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
    });
  });
}

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
  var container = sender.closest('.comment');
  var parent = sender.getAttribute('href');
  var parentEl = document.querySelector(parent);
  // This is begging for a refactor.
  if (parentEl) {
    if (parentEl.classList.contains('inline')) {
      // Prepend
      container.parentNode.insertBefore(parentEl, container.parentNode.firstChild);
    }
    jSlim.all('.comment.highlight', function(a) {
      a.classList.remove('highlight');
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
  const textarea = sender.closest('.page, body').querySelector('.post-box textarea');
  insertTags(textarea, '\n>>' + sender.dataset.oId + ' [q]\n' + jSlim.dom.decodeEntities(sender.dataset.comment) + '\n[/q]\n\n', '');
  let height = parseFloat(textarea.style.height) || 0;
  textarea.style.height = Math.max(height, textarea.scrollHeight) + 'px';
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
  '.comment .remove-comment': removeComment,
  '.reply-comment': replyTo,
  '.edit-comment-submit': editComment,
  '.spoiler': revealSpoiler
};

jSlim.on(document, 'accept', '.remove-comment', function(event) {
  var self = this;
  ajax.delete(self.getAttribute('href')).json(function(json) {
    removeComment(self.closest('.comment'), json);
  });
});

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


jSlim.ready(function() {
  if (document.location.hash.indexOf('#comment_') == 0) {
    lookupComment(document.location.hash.split('_')[1]);
  }
});
