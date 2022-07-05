import { all } from '../../jslim/dom';
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
  this.norm = relative(el, '.post-tags', '.normal.tags');

  this.tagTemplate = el.querySelector('.js-tag-template').innerHTML;
  if (this.norm) {
    const displayEL = el.querySelector('.js-display-template');
    this.displayTemplate = displayEL ? displayEL.innerHTML : '';
  }

  addDelegatedEvent(el, 'click', 'i.remove', (e, target) => {
    removeTag(this, target.parentNode);
  });

  inputHandler(this);

  this.reload = tags => {
    this.tags = tagSet(tags);
    save(this);
  };
}

function relative(el, parent, selector) {
  el = el.closest(parent);
  return el ? el.querySelector(selector) : el;
}

function initEditors() {
  all('.tag-editor', getTagEditor);
}

ready(initEditors);
bindEvent(document, 'ajax:externalform', () => {
  requestAnimationFrame(initEditors);
});
