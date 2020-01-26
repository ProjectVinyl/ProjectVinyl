import { getAppKey } from '../data/all';
import { ajax } from '../utils/ajax';
import { all } from '../jslim/dom';
import { addDelegatedEvent, ready, bindEvent } from '../jslim/events';

let active = null;
const keyEvents = { 66: 'b', 85: 'u', 73: 'i', 83: 's', 80: 'spoiler' };
const emoticons = getAppKey('emoticons_array');

const specialActions = {
  tag: (sender, textarea) => {
    const tag = sender.dataset.tag;
    insertTags(textarea, `[${tag}]`, sender.dataset.close ? '' : `[/${tag}]`);
  },
  emoticons: sender => {
    sender.classList.remove('edit-action');
    sender.querySelector('.pop-out').innerHTML = emoticons.map(e => `<li class="edit-action" data-action="emoticon" title=":${e}:">
      <span class="emote" data-emote="${e}" title=":${e}:"></span>
    </li>`).join('');
  },
  emoticon: (sender, textarea) => insertTags(textarea, sender.title, '')
};

export function insertTags(textarea, open, close) {
  const start = textarea.selectionStart;
  if (start === undefined || start === null) return;
  const end = textarea.selectionEnd;
  
  let selected = textarea.value.substring(start, end);
  
  if (selected.indexOf(open) > -1 || (selected.indexOf(close) > -1 && close)) {
    selected = selected.replace(open, '').replace(close, '');
  } else {
    selected = open + selected + close;
  }
  
  const before = textarea.value.substring(0, start);
  const after = textarea.value.substring(end, textarea.value.length);
  
  textarea.value = `${before}${selected}${after}`;
  textarea.selectionStart = start;
  textarea.selectionEnd = start + selected.length;
  textarea.focus();
}

function deactivate() {
	if (active) active.click();
  active = null;
}

function initEditable(textarea, content) {
  if (!textarea) {
    textarea = document.createElement('input');
    textarea.className = 'input js-auto-resize';
    textarea.value = content.innerHTML;
    content.insertAdjacentElement('afterend', textarea);
  }
  return textarea;
}

export function setupEditable(sender) {
  const content = sender.querySelector('.content');
  const button = sender.querySelector('.edit');
  const textarea = initEditable(sender.querySelector('.input'), content);
  
  button.addEventListener('click', e => {
    if (active != button) deactivate();
    if (toggleEdit(e, sender, content, textarea)) {
      active = button;
    }
  });
  sender.addEventListener('click', ev => ev.stopPropagation());
}

function toggleEdit(e, holder, content, textarea) {
  holder.classList.toggle('editing');
	
  if (holder.classList.contains('editing')) {
    const hovercard = content.querySelector('.hovercard');
    if (hovercard) hovercard.parentNode.removeChild(hovercard);
    requestAnimationFrame(() => {
      textarea.focus();
      textarea.dispatchEvent(new CustomEvent('keyup', e)); // ensure input size is correct
    });
    return true;
  }
  
  if (!holder.classList.contains('dirty')) return;
  
  holder.classList.add('loading');
  let path = holder.dataset.target;
  
  if (!path) {
    content.innerHTML = textarea.value;
    return;
  }
  
  if (holder.dataset.id) path += `/${holder.dataset.id}`;
  
  ajax.patch(path, {
    field: holder.dataset.member, value: holder.querySelector('.input').value
  }).json(json => {
    content.innerHTML = json.content;
    holder.classList.remove('loading');
    holder.classList.remove('dirty');
  });
}

addDelegatedEvent(document, 'change', '.editable', (ev, target) => target.classList.add('dirty'));
addDelegatedEvent(document, 'keydown', 'textarea.comment-content, .editable textarea.input', (ev, target) => {
  if (!ev.ctrlKey) return;
  const tag = keyEvents[ev.keyCode];
  if (tag) {
    ev.preventDefault();
    return insertTags(target, `[${tag}]`, `[/${tag}]`);
  }
  if (key == 13) deactivate();
});
addDelegatedEvent(document, 'mouseup', '.edit-action', (e, target) => {
  const type = specialActions[target.dataset.action];
  if (type) type(target, target.closest('.content').querySelector('textarea, input.comment-content'));
});
addDelegatedEvent(document, 'dragstart', '#emoticons .emote[title]', (event, target) => {
  let data = event.dataTransfer.getData('Text/plain');
  if (data && data.trim().indexOf('[') == 0) {
    data = data.split('\n').map(a => a.trim().replace(/\[/g, '').replace(/\]/g, '')).join('');
    event.dataTransfer.setData('Text/plain', data);
  } else {
    event.dataTransfer.setData('Text/plain', target.title);
  }
});

bindEvent(document, 'click', () => {
  if (active && !active.closest('.editable:hover')) deactivate();
});

ready(() => all('.editable', setupEditable));
