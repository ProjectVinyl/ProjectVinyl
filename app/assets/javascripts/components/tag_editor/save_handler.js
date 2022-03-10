import { fillTemplate } from '../../utils/template';

export function save(editor) {
  editor.textarea.value = editor.tags.join(',');
  editor.list.innerHTML = editor.tags.map(tag => fillTemplate(tag, editor.tagTemplate)).join('');
  if (editor.norm) {
    editor.norm.innerHTML = editor.tags.map(tag => fillTemplate(tag, editor.displayTemplate)).join('');
  }
  editor.dom.dispatchEvent(new CustomEvent('tagschange', { bubbles: true }));
}
