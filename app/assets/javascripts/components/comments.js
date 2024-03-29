import { ajaxGet, ajaxDelete, ajaxPatch } from '../utils/ajax';
import { repaintPagination } from './paginator';
import { popupConfirm, popupError } from './popup';
import { scrollTo } from '../ui/scroll';
import { ready, bindEvent } from '../jslim/events';
import { decodeEntities } from '../jslim/dom';
import { insertTags } from '../ui/editable/bbcode';
import { makeForm, makeInput } from '../ujs/method';
import { sendForm } from '../utils/xhr';

function postComment(sender) {
  const content = sender.closest('.content');

  const input = content.querySelector('textarea, input.comment-content');
  if (!input.value.trim()) return popupError('You have to type something to post!');

  content.classList.add('posting');
  const form = makeForm(sender.dataset.url, 'POST');
  form.appendChild(makeInput('[thread_id]', sender.dataset.threadId));
  form.appendChild(makeInput('order', sender.dataset.order));
  form.appendChild(makeInput('anonymous', sender.dataset.anonymous));
  form.appendChild(makeInput('comment', input.value));

  const captcha = content.querySelector('textarea.g-recaptcha-response');
  if (captcha) {
    form.appendChild(makeInput('g-recaptcha-response', captcha.value));
  }
  document.body.appendChild(form);

  sendForm(form, {
    success: json => {
      content.classList.remove('posting');
      form.parentNode.removeChild(form);
      if (json.error) return popupError(json.error);
      input.value = '';
      repaintPagination(document.getElementById(`thread-${sender.dataset.threadId}`).closest('.paginator'), json);
      scrollTo(document.getElementById(`comment_${json.focus}`));
    }
  });
}

function removeComment(sender) {
  popupConfirm("Are you sure you want to continue?", sender.dataset.title).setOnAccept(() => {
    ajaxDelete(sender.getAttribute('href')).json(json => {
      const el = sender.closest('.comment');
      
      el.style.height = `${el.offsetHeight}px`;
      requestAnimationFrame(() => {
        el.classList.add('hidden');
        if (json.content) {
          el.insertAdjacentHTML('afterend', json.content);
          el.nextSibling.style.height = `${el.nextSibling.offsetHeight}px`;
          el.nextSibling.classList.add('hidden');
          requestAnimationFrame(() => {
            el.nextSibling.classList.remove('hidden');
          });
        }
        
        setTimeout(() => el.parentNode.removeChild(el), 500);
      });
    });
  });
}

function scrollToAndHighlightElement(comment) {
  if (!comment) return;
  document.querySelectorAll('.comment.highlight').forEach(a => a.classList.remove('highlight'));
  scrollTo(comment);
  comment.classList.add('highlight');
  return true;
}

function scrollToAndHighlight(commentId) {
  return scrollToAndHighlightElement(document.getElementById(`comment_${commentId}`));
}

function lookupComment(commentId) {
  if (scrollToAndHighlight(commentId)) return;
  
  const pagination = document.querySelector('.comments').parentNode;
  ajaxGet(pagination.dataset.type, `comment=${commentId}&${pagination.dataset.args}`).json(json => {
    repaintPagination(pagination, json);
    scrollToAndHighlight(commentId);
  });
}

function editComment(sender) {
  sender = sender.closest('.content');
  ajaxPatch(`/comments/${sender.dataset.id}`, {
    comment: sender.querySelector('textarea, input.comment-content').value
  }).json(json => {
    sender.querySelector('.preview').innerHTML = json.content;
    sender.classList.remove('editing');
  });
}

function moveInlineComment(sender, container, type, commentEl) {
  const recurse = container.classList.contains('comment-content');
  if (recurse) container = getSubCommentList(sender);
  container[`insertAdjacent${type}`](recurse ? 'afterbegin' : 'beforebegin', commentEl);
  return container;
}

function focusComment(container, commentEl) {
  if (!container.classList.contains('hidden')) {
    scrollToAndHighlightElement(commentEl);
  }
}

function findComment(sender) {
  let container = sender.closest('.comment, .comment-content');
  const comment = sender.getAttribute('href');
  
  let commentEl = document.querySelector(comment);
  if (commentEl) {
    if (commentEl.classList.contains('inline')) {
      container = moveInlineComment(sender, container, 'Element', commentEl);
    }
    return focusComment(container, commentEl);
  }
  
  ajaxGet('find/comments', {
    id: sender.dataset.id || parseInt(comment.split('_')[1], 36)
  }).text(html => {
    container = moveInlineComment(sender, container, 'HTML', html);
    commentEl = document.querySelector(comment);
    commentEl.classList.add('inline');
    focusComment(container, commentEl);
  });
}

function getSubCommentList(sender) {
  if (!sender.nextElementSibling || !sender.nextElementSibling.classList.contains('comments')) {
    sender.insertAdjacentHTML('afterend', '<ul class="comments hidden"></ul>');
  }
  sender.nextSibling.classList.toggle('hidden');
  return sender.nextSibling;
}

function replyTo(sender) {
  sender = sender.closest('.content');
  const textarea = sender.closest('.page, body').querySelector('.post-box textarea');
  insertTags(textarea, `>>${sender.dataset.oId} [q]\n${decodeEntities(sender.dataset.comment)}\n[/q]\n`, '');
  let height = parseFloat(textarea.style.height) || 0;
  textarea.style.height = Math.max(height, textarea.scrollHeight) + 'px';
}

function reportState(sender) {
  sender = sender.parentNode.querySelector('input:checked').getAttribute('name');
	return sender && (sender.getAttribute('name') || false);
}

function revealSpoiler(target) {
  target.classList.toggle('revealed');
}

const targets = {
  '.post-submitter': postComment,
  '.comment .mention, .comment .comment-content a[data-link="2"]': findComment,
  '.comment .remove-comment': removeComment,
  '.reply-comment': replyTo,
  '.edit-comment-submit': editComment,
  '.spoiler': revealSpoiler
};

bindEvent(document, 'click', event => {
  if (event.which !== 1 && event.button !== 0) return;
  
  for (const target in targets) {
    let el = event.target.closest(target);
    if (el) {
      event.preventDefault();
      return targets[target](el);
    }
  }
});


ready(() => {
  if (document.location.hash.indexOf('#comment_') == 0) {
    lookupComment(document.location.hash.split('_')[1]);
  }
  document.querySelectorAll('.post-submitter').forEach(i => i.classList.remove('disable'));
});
