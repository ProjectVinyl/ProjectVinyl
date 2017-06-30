import { fetchJson, fetchHtml } from '../utils/requests.js';
import { paginator } from './paginator.js';
import { error } from './popup.js';
import { scrollTo } from '../ui/scroll.js';
import { decodeEntities } from '../utils/misc.js';

// app/views/thread/_comment_box.html.erb
// app/views/thread/_view_reverse.erb
window.postComment = function postComment(sender, threadId, order, reportState) {
  sender = sender.parentNode;
  let input = sender.querySelector('textarea, input.comment-content');
  let comment = input.value.trim();
  if (!comment.length) return error('You have to type something to post');

  const data = {
    thread: threadId,
    order: order,
    comment: comment
  };

  if (reportState) data.report_state = reportState;

  sender.classList.add('posting');

  fetchJson('POST', '/ajax/comments/new', data)
    .then(response => response.json())
    .then(json => {
      sender.classList.remove('posting');
      paginator.repaint($('#thread-' + threadId).closest('.paginator'), json);
      scrollTo('#comment_' + json.focus);
      input.value = '';
    });
};

// app/views/thread/_comment.html.erb
window.removeComment = function removeComment(id, json) {
  const el = document.querySelector(`#comment_${id}`);
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
  requestAnimationFrame(() => {
    el.style.opacity = '0';
    el.style.height = '0';
  });

  setTimeout(() => el.parentNode.removeChild(el), 500);
};

function scrollToAndHighlight(commentId) {
  const comment = document.querySelector(`#comment_${commentId}`);
  if (comment) {
    scrollTo($(comment));
    comment.classList.add('highlight');
    return true;
  }
}

function lookupComment(commentId) {
  if (scrollToAndHighlight(commentId)) return;

  const pagination = document.querySelector('.comments').parentNode;
  fetchJson('GET', `${pagination.dataset.type}?comment=${commentId}&${pagination.dataset.args}`)
    .then(response => response.json())
    .then(json => {
      paginator.repaint(pagination, json);
      scrollToAndHighlight(commentId);
    });
}

function editComment(sender) {
  sender = sender.parentNode;

  const data = {
    id: sender.dataset.id,
    comment: sender.querySelector('textarea, input.comment-content').value
  };

  fetchJson('POST', '/ajax/comments/edit', data)
    .then(response => response.text())
    .then(() => {
      sender.classList.remove('editing');
    });
}

function findComment(sender) {
  const container = sender.closest('comment');
  let parent = sender.attr('href');
  const parentEl = document.querySelector(parent);

  // This is begging for a refactor.
  if (parentEl) {
    if (parentEl.classList.contains('inline')) {
      // Prepend
      container.parentNode.insertBefore(parentEl, container.parentNode.firstChild);
    }
    $('.comment.highlight').removeClass('highlight');
    return scrollTo(parentEl).addClass('highlight');
  }

  const data = {
    id: sender.dataset.id || parseInt(parent.split('_')[1], 36)
  };

  fetchHtml('GET', '/ajax/comments/get', data)
    .then(response => response.text())
    .then(html => {
      container.parentNode.insertAdjacentHTML('afterbegin', html);
      parent = scrollTo(parent);
      if (parent) parent.addClass('highlight').addClass('inline');
    });
}

function replyTo(sender) {
  sender = sender.parentNode;
  const textarea = sender.closest('.page, body').querySelector('.post-box textarea');
  textarea.value = `>>${sender.dataset.oId} [q]\n${decodeEntities(sender.dataset.comment)}\n[/q]${textarea.value}`;
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

const targets = {
  '.comment .mention, .comment .comment-content a[data-link="2"]': findComment,
  '.reply-comment': replyTo,
  '.edit-comment-submit': editComment,
  '.spoiler': revealSpoiler
};

function onReady() {
  document.addEventListener('click', event => {
    // Left-click only
    if (event.button !== 0) return;

    for (const target in targets) {
      if (event.target.closest(target)) {
        targets[target](event.target.closest(target));
        event.preventDefault();
      }
    }
  });

  if (document.location.hash.indexOf('#comment_') == 0) {
    lookupComment(document.location.hash.split('_')[1]);
  }
}

if (document.readyState !== 'loading') onReady();
else document.addEventListener('DOMContentLoaded', onReady);
