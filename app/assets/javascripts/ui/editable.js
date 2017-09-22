import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';
import { BBCode } from '../utils/bbcode';

let active = null;
const emptyMessage = 'A description has not been written yet.';
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
  if (key == 13) deactivate(active);
}

function initEditable(holder, content, short) {
  let textarea = holder.querySelector('.input');
  if (!textarea) {
    textarea = document.createElement(short ? 'input' : 'textarea');
    textarea.className = 'input js-auto-resize';
    content.insertAdjacentElement('afterend', textarea);
  }
  return textarea;
}

export function insertTags(textarea, open, close) {
  const start = textarea.selectionStart;
  if (!start && start != 0) return;
  const end = textarea.selectionEnd;
  
  let selected = end - start > 0 ? textarea.value.substring(start, end) : '';
  
  if (selected.indexOf(open) > -1 || (selected.indexOf(close) > -1 && close)) {
    selected = selected.replace(open, '').replace(close, '');
  } else {
    selected = open + selected + close;
  }
  
	const before = textarea.value.substring(0, start);
	const after = textarea.value.substring(end, textarea.value.length);
	
  textarea.value = before + selected + after;
  textarea.selectionStart = start;
  textarea.selectionEnd = start + selected.length;
  textarea.focus();
  updatePreview(textarea);
}

function toggleEdit(editing, holder, content, textarea, short) {
  const text = content.innerText.toLowerCase().trim();
  if (!editing) {
    const hovercard = content.querySelector('.hovercard');
    if (hovercard) hovercard.parentNode.removeChild(hovercard);
    textarea.value = BBCode.fromHTML(content.innerHTML).outerBBC();
    holder.classList.add('editing');
    textarea.dispatchEvent(new Event('keyup'));
		return true;
  }
	if (!text || !text.length || text === emptyMessage.toLowerCase()) {
		content.innerText = emptyMessage;
	}
	if (short) {
		content.innerText = BBCode.fromHTML(textarea.value).outerBBC();
	} else {
		content.innerHTML = BBCode.fromBBC(textarea.value).outerHTML();
	}
	holder.classList.remove('editing');
	updatePreview(textarea);
}

function save(action, id, field, holder) {
  if (!holder.classList.contains('dirty')) return;
	holder.classList.add('saving');
	ajax.patch(`${action}/${id}`, {
		field: field,
		value: BBCode.fromBBC(holder.querySelector('.input').value).outerBBC()
	}).text(() => {
		holder.classList.remove('saving');
		holder.classList.remove('dirty');
	});
}

function deactivate(button) {
  active = null;
  button.click();
}

export function setupEditable(sender) {
  let editing = false;
  const target = sender.dataset.target;
  const short = sender.classList.contains('short');
  const content = sender.querySelector('.content');
  const button = sender.querySelector('.edit');
  const textarea = initEditable(sender, content, short);
  
  button.addEventListener('click', () => {
    if (active && active != button) deactivate(active);
    editing = toggleEdit(editing, sender, content, textarea, short);
    active = editing ? button : null;
    if (!editing && target) {
      save(target, sender.dataset.id, sender.dataset.member, sender);
    }
  });
  sender.addEventListener('click', ev => ev.stopPropagation());
}

document.addEventListener('click', () => {
  if (active && !active.closest('.editable:hover')) deactivate(active);
});

function updatePreview(sender) {
  const preview = sender.parentNode.querySelector('.comment-content.preview');
  if (preview) preview.innerHTML = BBCode.fromBBC(sender.value).outerHTML();
}

jSlim.on(document, 'change', '.editable', (ev, target) => target.classList.add('dirty'));
jSlim.on(document, 'change', 'textarea.comment-content', (e, target) => updatePreview(target));
jSlim.on(document, 'keydown', 'textarea.comment-content, .editable textarea.input', (ev, target) => {
  if (ev.ctrlKey) handleSpecialKeys(ev.keyCode, tag => {
		insertTags(target, `[${tag}]`, `[/${tag}]`);
		ev.preventDefault();
	});
});

jSlim.on(document, 'mouseup', '.edit-action', (e, target) => {
  const type = specialActions[target.dataset.action];
  if (type) type(target, target.closest('.content').querySelector('textarea, input.comment-content'));
});

jSlim.on(document, 'dragstart', '#emoticons .emote[title]', (event, target) => {
  let data = event.dataTransfer.getData('Text/plain');
  if (data && data.trim().indexOf('[') == 0) {
    data = data.split('\n').map(a => a.trim().replace(/\[/g, '').replace(/\]/g, '')).join('');
    event.dataTransfer.setData('Text/plain', data);
  } else {
    event.dataTransfer.setData('Text/plain', target.title);
  }
});

jSlim.ready(() => {
  jSlim.all('.editable', setupEditable);
  jSlim.all('.post-box textarea.comment-content, .post-box input.comment-content', updatePreview);
});
