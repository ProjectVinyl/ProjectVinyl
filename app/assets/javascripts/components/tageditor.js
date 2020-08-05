import { Key } from '../utils/key';
import { all } from '../jslim/dom';
import { addDelegatedEvent, ready, halt, bindEvent } from '../jslim/events';

function fillTemplate(obj, template) {
  Object.keys(obj).forEach(key => {
    template = template.replace(new RegExp(`{${key}}`, 'g'), obj[key]);
  });
  return template;
}

function tagSet(arr) {
  const toS = a => (a.name || a.toString()).trim();
  arr.baked = function() {
    return this.map(toS);
  };
  arr.join = function() {
    return Array.prototype.join.apply(this.baked(), arguments);
  };
  arr.indexOf = function(e, i) {
    const result = Array.prototype.indexOf.apply(this, arguments);
    return result > -1 ? result : Array.prototype.indexOf.call(this.baked(), toS(e), i);
  };
  arr.remove = function(item) {
    this.splice(this.indexOf(item), 1);
  };
  return arr;
}

function asTag(ans) {
  if (ans.name) return ans;
  const namespace = ans.indexOf(':') == -1 ? '' : ans.split(':')[0];
  return {
    name: ans,
    slug: ans.replace(`${namespace}:`, ''),
    namespace: namespace,
    members: -1,
    flags: '',
    link: ans
  };
}

function inputHandler(sender) {
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

function TagEditor(el) {
  el.getActiveTagsArray = () => this.tags;
  el.getTagEditorObj = () => this;
  
  this.history = [[], []]; // past, future
  
  this.dom = el;
  this.tags = tagSet(JSON.parse(el.querySelector('.js-data-store').innerText));
  this.textarea = el.querySelector('.value textarea');
  this.textarea.value = this.tags.join(',');
  
  this.list = el.querySelector('ul.tags');
  this.norm = el.parentNode.parentNode.querySelector('.normal.tags');
  
  this.tagTemplate = el.querySelector('.js-tag-template').innerHTML;
  if (this.norm) this.displayTemplate = el.querySelector('.js-display-template').innerHTML;
  
  addDelegatedEvent(el, 'click', 'i.remove', (e, target) => {
    removeTag(this, target.parentNode);
  });
  
  inputHandler(this);
  
  this.reload = tags => {
    this.tags = tagSet(tags);
    save(this);
  };
}

function pushHistory(history, tag, action) {
  history[0].push({type: action, tag: tag});
  history[1].length = 0;
}

function popHistory(sender, direction) {
  const source = sender.history[direction];
  const dest = sender.history[(direction + 1) % 2];
  if (!source.length) return;
  const item = source.pop();
  dest.push(item);
  if (item.type === direction) {
    sender.tags.push(item.tag);
  } else {
    sender.tags.remove(item.tag);
  }
  save(sender);
}

function addTag(editor, tag) {
  tag = asTag(tag);
  if (!tag.name.length || tag.name.indexOf('uploader:') === 0 || tag.name.indexOf('title:') === 0) return;
  if (editor.tags.indexOf(tag) > -1) return;
  editor.tags.push(tag);
  pushHistory(editor.history, tag, 1);
}

function removeTag(editor, item) {
  const tag = editor.tags.find(a => a.namespace == item.dataset.namespace && a.slug == item.dataset.slug);
  if (!tag) return console.error(`tag "${tag}" not found.`);
  editor.tags.remove(tag);
  
  pushHistory(editor.history, tag, 0);
  save(editor);
}

function save(editor) {
  editor.textarea.value = editor.tags.join(',');
  editor.list.innerHTML = editor.tags.map(tag => fillTemplate(tag, editor.tagTemplate)).join('');
  if (editor.norm) {
    editor.norm.innerHTML = editor.tags.map(tag => fillTemplate(tag, editor.displayTemplate)).join('');
  }
  editor.dom.dispatchEvent(new CustomEvent('tagschange', { bubbles: true }));
}

export function getTagEditor(el) {
  return el.getTagEditorObj ? el.getTagEditorObj() : new TagEditor(el);
}

function initEditors() {
  all('.tag-editor', getTagEditor);
}

ready(initEditors);
bindEvent(document, 'ajax:externalform', () => {
  requestAnimationFrame(initEditors);
});
