import { addDelegatedEvent } from '../../jslim/events';
import { deactivate } from './inline_textbox';
import { insertTags } from './bbcode';

const keyEvents = { 66: 'b', 85: 'u', 73: 'i', 83: 's', 80: 'spoiler' };

addDelegatedEvent(document, 'keydown', 'textarea.comment-content, .editable textarea.input', (ev, target) => {
  if (!ev.ctrlKey) return;
  const tag = keyEvents[ev.keyCode];
  if (tag) {
    ev.preventDefault();
    return insertTags(target, `[${tag}]`, `[/${tag}]`);
  }
  if (ev.keyCode == 13) {
    deactivate();
  }
});
