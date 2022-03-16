import { all } from '../../jslim/dom';
import { addDelegatedEvent } from '../../jslim/events';
import { getTagEditor } from '../tag_editor/all';

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el} = e.detail.data;

  all(el, '.tag-editor', getTagEditor);
});
