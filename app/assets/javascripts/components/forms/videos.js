import { addDelegatedEvent } from '../../jslim/events';
import { popupError } from '../popup';
import { getTagEditor } from '../tag_editor/all';

addDelegatedEvent(document, 'ajax:complete', 'form.js-edit-video', (e, sender) => {
  const {data} = e.detail;

  if (data.error) {
    return popupError(data.error.msg, data.error.title);
  }

  const tagEditor = sender.querySelector('textarea[name="tags"]').closest('.tag-editor');
  const sourceEditor = sender.querySelector('textarea[name="source"]').closest('.tag-editor');

  tagEditor.getTagEditorObj().reload(data.tags);
  sourceEditor.getTagEditorObj().reload(data.sources);

  const sources = sender.closest('.post-tags').querySelector('.normal .video-sources');

  if (sources) {
    sources.innerHTML = data.html.sources;
  }

  const tags = sender.closest('.post-tags').querySelector('.normal .tags');

  if (tags) {
    tags.innerHTML = data.html.tags;
  }
});
