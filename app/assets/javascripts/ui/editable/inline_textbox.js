import { ajax } from '../../utils/ajax';
import { addDelegatedEvent, bindEvent } from '../../jslim/events';

let active = null;

export function insertTags(textarea, open, close, endSelect) {
  const start = textarea.selectionStart;
  if (start === undefined || start === null) {
    return;
  }

  const end = textarea.selectionEnd;
  
  let selected = textarea.value.substring(start, end);
  
  if ((open && selected.indexOf(open) > -1) || (close && selected.indexOf(close) > -1)) {
    selected = selected.replace(open, '').replace(close, '');
  } else {
    selected = open + selected + close;
  }
  
  const before = textarea.value.substring(0, start);
  const after = textarea.value.substring(end, textarea.value.length);
  
  textarea.value = `${before}${selected}${after}`;
  textarea.selectionStart = endSelect ? start + selected.length : start;
  textarea.selectionEnd = start + selected.length;
  textarea.focus();
}

export function deactivate() {
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

addDelegatedEvent(document, 'click', '.editable .edit', event => {
  const sender = event.target.closest('.editable');
  const content = sender.querySelector('.content');
  const button = sender.querySelector('.edit');

  if (active != button) {
    deactivate();
  }
  if (toggleEdit(event, sender, content, initEditable(sender.querySelector('.input'), content))) {
    active = button;
  }
});

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
bindEvent(document, 'click', () => {
  if (active && !active.closest('.editable:hover')) deactivate();
});
