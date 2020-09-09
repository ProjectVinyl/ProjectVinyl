import { addDelegatedEvent } from '../jslim/events';
import { insertTags } from '../ui/editable/bbcode';

function getFocusedTagSlug(input) {
  const start = input.selectionStart;

  const before = splitTags(input.value.substr(0, input.selectionStart), /[,\(\)]/);
  const after = splitTags(input.value.substr(input.selectionStart), ',');

  return (before.reverse()[0] + after[0]).trim();
}

function splitTags(value, reg) {
  const output = [];
  let partialBefore = null, partialAfter = null;

  value = value.split('"');
  value.forEach((item, index) => {
    if (index % 2 == 0) {
      let parts = item.split(reg);
      if (index > 0) {
        partialBefore = parts.shift();
      }
      if (parts.length && index < value.length - 1) {
        partialAfter = parts.pop();
      }
      output.push.apply(output, parts);
    } else {
      let parts = [];
      if (partialAfter != null) {
        parts.push(partialAfter);
        partialAfter = null;
      }
      parts.push(item);
      if (partialBefore != null) {
        parts.push(partialBefore);
        partialBefore = null;
      }

      output.push(parts.join('"'));
    }
  });
  return output;
}

addDelegatedEvent(document, 'click', '.meta-toolbar[data-target] [data-insert]', (e, target) => {
  const toolbar = target.closest('[data-target]');
  const input = document.querySelector(`#${toolbar.dataset.target} input[name="q"]`);

  let before = '';
  let after = target.dataset.insert;
  let value = target.dataset.value;

  if (target.dataset.insertPosition == 'before') {
    const lastTag = getFocusedTagSlug(input);
    if (lastTag) {
      const start = input.value.lastIndexOf(lastTag);
      input.selectionStart = start;
      input.selectionEnd = start + lastTag.length;
    }
    before = after;
    after = '';
  } else {  
    if (input.value) {
      after = ', ' + after;
    }
  }

  insertTags(input, before, after, true);

  if (value) {
    insertTags(input, '', value);
  }
});
