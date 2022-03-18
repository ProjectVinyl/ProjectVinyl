import { addDelegatedEvent } from '../../jslim/events';
import { popupError } from '../popup';
import { getTagEditor } from '../tag_editor/all';

addDelegatedEvent(document, 'ajax:complete', 'form.js-edit-video', (e, sender) => {
  const data = e.detail.data;

  if (data.error) {
    return popupError(data.error.msg, data.error.title);
  }

  const source = sender.parentNode.querySelector('.normal.tiny-link a');
  sender.querySelector('.tag-editor').getTagEditorObj().reload(data.results);
  source.innerText = source.href = data.source;
});
