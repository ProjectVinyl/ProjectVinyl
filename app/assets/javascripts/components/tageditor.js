import { ajax } from '../utils/ajax';
import { Key } from '../utils/misc';
import { all } from '../jslim/dom';
import { addDelegatedEvent, ready, halt } from '../jslim/events';

function createTagItem(tag) {
  return `<li class="tag tag-${tag.namespace}" data-namespace="${tag.namespace}" data-slug="${tag.slug}">
    <i title="Remove Tag" data-name="${tag.name}" class="fa fa-times remove"></i><a href="/tags/${tag.link}">${tag.name}</a>
  </li>`;
}

function createDisplayTagItem(tag) {
  return `<li class="tag tag-${tag.namespace} drop-down-holder popper" data-namespace="${tag.namespace}" data-slug="${tag.slug}">
    <a href="/tags/${tag.link}">
      <span>${tag.name}</span>${tag.members > -1 ? ` (${tag.members})` : ''}
    </a>
    <ul class="drop-down pop-out">${['Hide', 'Spoiler', 'Watch'].map(a =>
      `<li class="action toggle" data-family="tag-flags" data-descriminator="${a.toLowerCase()}" data-action="${a.toLowerCase()}" data-target="tag" data-id="${tag.name}">
        <span class="icon"></span><span class="label">${a}</span>
      </li>`).join('')}</ul>
  </li>`;
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
        removeTag(sender, sender.list.lastChild);
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
    if (!e.target.closest('i')) input.focus();
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
  
  autoCompleteHandler(input, sender);
}
// TODO: Move to autocomplete.js
function autoCompleteHandler(input, sender) {
  const searchResults = sender.dom.querySelector('.search-results');
  
  let autocomplete = null;
  let lastValue = '';
  
  let searchResultResults = [];
  
  input.addEventListener('focus', () => {
    if (autocomplete) return;
    autocomplete = setInterval(() => {
      const value = input.value.trim().split(/,|;/).reverse()[0].trim().toLowerCase();
      if (value.length && value != lastValue) {
        lastValue = value;
        doSearch(value);
      }
    }, 1000);
    sender.dom.classList.add('focus');
    sender.dom.classList.toggle('pop-out-shown', searchResults.children.length);
  });
  input.addEventListener('blur', () => {
    sender.dom.classList.remove('focus');
    if (!autocomplete) return;
    clearInterval(autocomplete);
    autocomplete = null;
  });
  
  addDelegatedEvent(searchResults, 'click', 'li[data-index]', (e, target) => {
    sender.dom.classList.remove('pop-out-shown');
    addTag(sender, searchResultResults[parseInt(target.dataset.index)]);
    save(sender);
    input.value = '';
  });
  
  function doSearch(name) {
    ajax.get('find/tags', { q: name }).json(json => {
      sender.dom.classList.toggle('pop-out-shown', !!json.results.length);
      searchResultResults = json.results;
      searchResults.innerHTML = searchResultResults.map((tag, i) => `<li class="tag-${tag.namespace}" data-slug="${tag.slug}" data-index="${i}">
        <span>${tag.name.replace(name, `<b>${name}</b>`)}</span> (${tag.members})
      </li>`).join('');
    });
  }
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
  
  addDelegatedEvent(el, 'click', 'i.remove', (e, target) => {
    removeTag(this, target.parentNode);
  });
  
  inputHandler(this);
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
    editor.tags.push(item.tag);
  } else {
    editor.tags.remove(item.tag);
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
  editor.list.innerHTML = editor.tags.map(createTagItem).join('');
  if (editor.norm) {
    editor.norm.innerHTML = editor.tags.map(createDisplayTagItem).join('');
  }
  editor.dom.dispatchEvent(new CustomEvent('tagschange', { bubbles: true }));
}

export function getTagEditor(el) {
  return el.getTagEditorObj ? el.getTagEditorObj() : new TagEditor(el);
}

ready(() => all('.tag-editor', a => new TagEditor(a)));
