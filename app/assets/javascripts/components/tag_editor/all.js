import { tagSet } from './tag_set';
import { removeTag } from './tag';
import { save } from './save_handler';
import { inputHandler } from './input_handler';
import { addDelegatedEvent, ready, bindEvent } from '../../jslim/events';

export function getTagEditor(el) {
  return el.getTagEditorObj ? el.getTagEditorObj() : new TagEditor(el);
}

function TagEditor(el) {
  el.getActiveTagsArray = () => this.tags;
  el.getTagEditorObj = () => this;

  this.history = [[], []]; // past, future

  this.dom = el;
  this.tags = tagSet(JSON.parse(el.querySelector('.js-data-store').innerText));
  this.textarea = el.querySelector('.value textarea');
  this.textarea.value = this.tags.join(',');

  this.list = el.querySelector('ul.tags');
  this.tagTemplate = el.querySelector('.js-tag-template').innerHTML;

  addDelegatedEvent(el, 'click', 'i.remove', (e, target) => {
    removeTag(this, target.parentNode);
  });

  inputHandler(this);

  this.reload = tags => {
    this.tags = tagSet(tags);
    save(this);
  };
}

function initEditors() {
  document.querySelectorAll('.tag-editor').forEach(getTagEditor);
}

ready(initEditors);
bindEvent(document, 'ajax:externalform', () => {
  requestAnimationFrame(initEditors);
});
