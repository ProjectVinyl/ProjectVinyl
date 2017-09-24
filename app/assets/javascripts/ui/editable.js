import { ajax } from '../utils/ajax';
import { all } from '../jslim/dom';
import { addDelegatedEvent, ready } from '../jslim/events';

let active = null;
const keyEvents = { 66: 'b', 85: 'u', 73: 'i', 83: 's', 80: 'spoiler' };

const specialActions = {
  tag: (sender, textarea) => {
    const tag = sender.dataset.tag;
    insertTags(textarea, `[${tag}]`, `[/${tag}]`);
  },
  emoticons: sender => {
    sender.classList.remove('edit-action');
    sender.querySelector('.pop-out').innerHTML = emoticons.map(e => `<li class="edit-action" data-action="emoticon" title=":${e}:">
			<span class="emote" data-emote="${e}" title=":${e}:"></span>
		</li>`).join('');
  },
  emoticon: (sender, textarea) => insertTags(textarea, sender.title, '')
};

function handleSpecialKeys(key, callback) {
  const k = keyEvents[key];
  if (k) return callback(k);
  if (key == 13) deactivate();
}

export function insertTags(textarea, open, close) {
  const start = textarea.selectionStart;
  if (start === undefined || start === null) return;
  const end = textarea.selectionEnd;
  
  let selected = textarea.value.substring(start, end);
  
  if (selected.indexOf(open) > -1 || (selected.indexOf(close) > -1 && close)) {
    selected = selected.replace(open, '').replace(close, '');
  } else {
    selected = `${open}${selected}${close}`;
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
  let editing = false;
  const content = sender.querySelector('.content');
  const button = sender.querySelector('.edit');
  const textarea = initEditable(sender.querySelector('.input'), content);
  
  button.addEventListener('click', () => {
    if (active != button) deactivate();
    if (toggleEdit(sender, content, textarea)) {
			active = button;
		}
  });
  sender.addEventListener('click', ev => ev.stopPropagation());
}

function toggleEdit(holder, content, textarea) {
  const text = content.innerText.toLowerCase().trim();
	
	holder.classList.toggle('editing');
	
  if (holder.classList.contains('editing')) {
    const hovercard = content.querySelector('.hovercard');
    if (hovercard) hovercard.parentNode.removeChild(hovercard);
    textarea.dispatchEvent(new Event('keyup')); // ensure input size is correct
		textarea.focus();
		return true;
  }
	
	if (!holder.classList.contains('dirty')) return;
	
	holder.classList.add('loading');
	ajax.patch(`${holder.dataset.target}/${holder.dataset.id}`, {
		field: holder.dataset.member,
		value: holder.querySelector('.input').value
	}).json(json => {
		content.innerHTML = json.content;
		holder.classList.remove('loading');
		holder.classList.remove('dirty');
	});
}

addDelegatedEvent(document, 'change', '.editable', (ev, target) => target.classList.add('dirty'));
addDelegatedEvent(document, 'keydown', 'textarea.comment-content, .editable textarea.input', (ev, target) => {
  if (ev.ctrlKey) handleSpecialKeys(ev.keyCode, tag => {
		insertTags(target, `[${tag}]`, `[/${tag}]`);
		ev.preventDefault();
	});
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

document.addEventListener('click', () => {
  if (active && !active.closest('.editable:hover')) deactivate();
});

ready(() => all('.editable', setupEditable));
