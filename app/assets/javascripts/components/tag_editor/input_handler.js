import { Key } from '../../utils/key';
import { addTag, removeTag } from './tag';
import { save } from './save_handler';
import { popHistory } from './history';
import { addDelegatedEvent, halt } from '../../jslim/events';

export function inputHandler(sender) {
  const input = sender.dom.querySelector('.input');
  
  let handledBack = false;
  const normalActions = {
    [Key.BACKSPACE]: sender => {
      if (handledBack) return false;
      handledBack = true;
      if (!input.value.length && sender.list.lastChild) {
        removeTag(sender, sender.list.lastElementChild);
      }
    },
    [Key.ENTER]: sender => {
      input.value.trim().split(/,|;/).forEach(tag => addTag(sender, tag));
      save(sender);
      input.value = '';
      handledBack = false;
      return false;
    }
  };
  const controlActions = {
    [Key.Z]: sender => popHistory(sender, 0),
    [Key.Y]: sender => popHistory(sender, 1)
  };
  
  sender.dom.addEventListener('mouseup', e => {
    if (!e.target.closest('li')) input.focus();
  });
  
  input.addEventListener('keydown', e => {
    let handler = normalActions[e.which == Key.COMMA ? Key.ENTER : e.which];;
    if (!handler && e.ctrlKey) handler = controlActions[e.which];
    
    if (handler) {
      if (handler(sender) === false) halt(e);
      return;
    }
    
    handledBack = false;
  });
  input.addEventListener('keyup', () => {
    handledBack = false;
  });
  
  sender.dom.addEventListener('lookup:complete', e => {
    e.stopPropagation(); //autocomplete.js
    e.target.innerHTML = e.detail.results.map((tag, i) => `<li class="tag-${tag.namespace}" data-slug="${tag.slug}" data-index="${i}">
      <span>${tag.name.replace(e.detail.term, `<b>${e.detail.term}</b>`)}</span> (${tag.members})
    </li>`).join('');
  });
  
  sender.dom.addEventListener('lookup:insert', e => {
    input.value = '';
    addTag(sender, e.detail);
    save(sender);
  });
}
