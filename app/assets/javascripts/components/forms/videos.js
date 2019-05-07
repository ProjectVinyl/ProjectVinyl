import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'ajax:complete', 'form.js-edit-video', (e, sender) => {
  const data = e.detail.data;
  const source = sender.parentNode.querySelector('.normal.tiny-link a');
  sender.querySelector('.tag-editor').getTagEditorObj().reload(data.results);
  source.innerText = source.href = data.source;
});
