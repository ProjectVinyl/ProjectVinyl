import { ajax } from '../utils/ajax.js';
import { Key } from '../utils/misc.js';
import { jSlim } from '../utils/jslim.js';

function namespace(name) {
  return name.indexOf(':') == -1 ? '' : name.split(':')[0];
}

function halt(ev) {
  ev.preventDefault();
  ev.stopPropagation();
}

function stopPropa(ev) {
  ev.stopPropagation();
}

function createBaseItem(container, tag, content) {
  var item = document.createElement('LI');
  item.classList.add('tag-' + tag.namespace);
  item.innerHTML = content;
  item.dataset.slug = tag.slug;
  item.tag = tag;
  container.appendChild(item);
  return item;
}

function createSearchItem(container, result, name) {
  createBaseItem(container, result, '<span>' + result.name.replace(name, '<b>' + name + '</b>') + '</span> (' + result.members + ')');
}

function createTagItem(container, tag) {
  var item = createBaseItem(container, tag, '<i title="Remove Tag" data-name="' + tag.name + '" class="fa fa-times remove"></i><a href="/tags/' + tag.link + '">' + tag.name + '</a>');
  item.classList.add('tag');
}

function tagAction(action, name) {
  var laction = action.toLowerCase();
  return '\
  <li class="action toggle" data-family="tag-flags" data-descriminator="' + laction + '" data-action="' + laction + '" data-target="tag" data-id="' + name + '">\
    <span class="icon"></span>\
    <span class="label">' + action + '</span>\
  </li>';
}

function createDisplayTagItem(container, tag) {
  var item = createBaseItem(container, tag, '\
    <a href="/tags/' + tag.link + '"><span>' + tag.name + '</span>' + (tag.members > -1 ? ' (' + tag.members + ')' : '') + '</a>\
    <ul class="drop-down pop-out">' + ['Hide','Spoiler','Watch'].map(function(a) {
      return tagAction(a, tag.name);
    }).join('') + '\
    </ul>');
  item.classList.add('tag');
  item.classList.add('drop-down-holder');
  item.classList.add('popper');
}

function asBakedArray(arr) {
  if (arr && arr.baked) return arr;
  arr = arr || [];
  arr.baked = function() {
    return this.map(function(a) {
      return a.toString();
    });
  };
  arr.join = function() {
    return Array.prototype.join.apply(this.baked(), arguments);
  };
  arr.indexOf = function(e, i) {
    var result = Array.prototype.indexOf.apply(this, arguments);
    return result > -1 ? result : Array.prototype.indexOf.call(this.baked(), e.toString(), i);
  };
  return arr;
}

function asTag(ans) {
  ans = ans.name ? ans : {
    namespace: namespace(ans),
    name: ans,
    members: -1,
    link: ans
  };
  ans.slug = ans.name.replace(ans.namespace + ':', '');
  ans.toString = function() {
    return this.name;
  };
  ans.valueOf = function() {
    return this.toString().valueOf();
  };
  return ans;
}

function invertAction(sender, item, forward, dest) {
  dest.unshift(item);
  if (forward) {
    sender.pickupTag(item.tag);
    sender.save();
  } else {
    forward = sender.list.querySelector('[data-name="' + item.tag.name + '"]');
    if (forward) sender.dropTag(forward.parentNode, item.tag);
  }
  dest.unshift(item);
}

function autoCompleteHandler(sender) {
  var autocomplete = null;
  var lastValue = '';
  
  sender.input.addEventListener('focus', function() {
    if (!autocomplete) {
      autocomplete = setInterval(function() {
        var value = sender.input.value;
        if (value != lastValue) {
          lastValue = value;
          sender.doSearch(value.trim().split(/,|;/).reverse()[0]);
        }
      }, 1000);
    }
    sender.dom.classList.add('focus');
  });
  sender.input.addEventListener('blur', function() {
    clearInterval(autocomplete);
    autocomplete = null;
    sender.dom.classList.remove('focus');
  });
}

function inputHandler(sender) {
  var handledBack = false;
  
  function backspace() {
    if (handledBack) return;
    handledBack = true;
    var value = sender.input.value;
    if (!value.length && sender.list.lastChild) {
      sender.removeTag(sender.list.lastChild);
    }
  }
  
  function enter() {
    sender.input.value.trim().split(/,|;/).forEach(function(t) {
      sender.appendTag(t);
    });
    sender.input.value = '';
    sender.save();
    handledBack = false;
    return true;
  }
  
  function handleKey(key, ctrlKey) {
    if (ctrlKey) {
      if (key == Key.Z) {
        sender.undo();
        return true;
      }
      if (key == Key.Y) {
        sender.redo();
        return true;
      }
    }
    if (key == Key.BACKSPACE) {
      return backspace();
    }
    if (key == Key.ENTER) {
      return enter();
    }
    handledBack = false;
  }
  
  sender.input.addEventListener('keydown', function(e) {
    var key = e.which;
    if (key == Key.COMMA) key = Key.ENTER;
    if (handleKey(key, e.ctrlKey)) {
      halt(e);
    }
    sender.sizeInput();
  });
  sender.input.addEventListener('keyup', function() {
    sender.sizeInput();
    handledBack = false;
  });
}

function TagEditor(el) {
  var self = this;
  
  this.history = [];
  this.future = [];
  
  jSlim.each(el.querySelectorAll('.values'), function(a) {
    a.parentNode.removeChild(a);
  });
  el.getActiveTagsArray = function() {
    return self.tags;
  };
  el.getTagEditorObj = function() {
    return self;
  };
  
  this.dom = el;
  this.input = el.querySelector('.input');
  this.value = el.querySelector('.value textarea');
  this.list = el.querySelector('ul.tags');
  this.searchResults = el.querySelector('.search-results');
  this.norm = null;
  
  this.tags = this.value.value.replace(/,,|^,|,$/g, '');
  this.target = this.value.dataset.target;
  this.id = this.value.dataset.id;
  
  
  if (el.parentNode.classList.contains('editing')) {
    this.norm = el.parentNode.parentNode.querySelector('.normal.tags');
  }
  this.loadTags(this.tags);
  
  inputHandler(this);
  autoCompleteHandler(this);
  
  this.input.addEventListener('mousedown', stopPropa);
  
  jSlim.on(this.searchResults, 'click', 'li', function(e) {
    self.fillSearchedTag(this.tag);
  });
  
  jSlim.on(this.list, 'click', 'i.remove', function(e) {
    self.removeTag(this.parentNode);
    stopPropa(e);
  });
  
  this.dom.addEventListener('mouseup', function(e) {
    self.input.focus();
    halt(e);
  });
  this.dom.addEventListener('mousedown', stopPropa);
}

TagEditor.getOrCreate = function(el) {
  return el.getTagEditorObj ? el.getTagEditorObj() : new TagEditor(el);
};

TagEditor.prototype = {
  loadTags: function(tags) {
    var unloadedSlugs = asBakedArray();
    
    if (tags.length) {
      if (tags.split) tags = tags.split(',');
      this.tags = asBakedArray(tags.map(asTag));
    } else {
      this.tags = asBakedArray();;
    }
    
    unloadedSlugs.push.apply(unloadedSlugs, this.tags);
    jSlim.each(this.list.childNodes, function(li) {
      var index = unloadedSlugs.indexOf(li.firstElementChild.dataset.name);
      if (index < 0) {
        li.parentNode.removeChild(li);
        return;
      }
      
      var item = unloadedSlugs.splice(index, 1)[0];
      item.namespace = li.dataset.namespace;
      li.tag = item;
    });
    unloadedSlugs.forEach(function(slug) {
      createTagItem(this.list, slug);
    }, this);
    
    this.value.value = this.tags.join(',');
  },
  fillSearchedTag: function(tag) {
    var text = this.input.value.trim().split(/,|;/);
    this.dom.classList.remove('pop-out-shown');
    text.pop();
    text.push(tag);
    text.forEach(function(t) {
      this.appendTag(t);
    }, this);
    this.input.value = '';
    this.sizeInput();
    this.save();
  },
  appendTag: function(tag) {
    tag = asTag(tag);
    if (tag.name.length && tag.name.indexOf('uploader:') != 0 && tag.name.indexOf('title:') != 0) {
      if (this.tags.indexOf(tag) == -1) {
        this.pickupTag(tag);
        this.history.unshift({type: 1, tag: tag});
        this.future.length = 0;
      }
    }
  },
  pickupTag: function(tag) {
    tag = asTag(tag);
    this.tags.push(tag);
    this.value.value = this.tags.join(',');
    createTagItem(this.list, tag);
  },
  removeTag: function(sender) {
    var tag = asTag(sender.tag);
    this.history.unshift({type: -1, tag: tag});
    this.future.length = 0;
    this.dropTag(sender, tag);
  },
  dropTag: function(sender, tag) {
    sender.parentNode.removeChild(sender);
    this.tags.splice(this.tags.indexOf(tag), 1);
    this.value.value = this.tags.join(',');
    this.save();
  },
  undo: function() {
    if (this.history.length) {
      var item = this.history.shift();
      invertAction(this, item, item.type <= 0, this.future);
    }
  },
  redo: function() {
    if (this.future.length) {
      var item = this.future.shift();
      invertAction(this, item, item.type > 0, this.history);
    }
  },
  reload: function(tags) {
    this.tags.length = 0;
    this.list.innerHTML = '';
    if (this.norm) this.norm.innerHTML = '';
    tags.forEach(function (t) {
      var tag = asTag(t);
      createTagItem(this.list, tag);
      if (this.norm) {
        createDisplayTagItem(this.norm, tag);
      }
    }, this);
    this.value.value = this.tags.join(',');
  },
  save: function() {
    var self = this;
    this.dom.dispatchEvent(new CustomEvent('tagschange'));
    if (this.target && this.id) {
      ajax.post('update/' + this.target, function(json) {
        self.reload(json.results);
      }, false, {
        id: this.id,
        field: 'tags',
        value: this.value.value
      });
    } else if (this.norm) {
      this.norm.innerHTML = '';
      this.tags.forEach(function(tag) {
        createDisplayTagItem(self.norm, tag);
      });
    }
  },
  doSearch: function(name) {
    var self = this;
    name = name.trim().toLowerCase();
    if (!name.length) {
      this.dom.classList.remove('pop-out-shown');
      return;
    }
    ajax.get('find/tags', function(json) {
      self.searchResults.innerHTML = '';
      json.results.forEach(function(result) {
        createSearchItem(self.searchResults, result, name);
      });
      self.dom.classList.toggle('pop-out-shown', !!json.results.length);
    }, { q: name });
  },
  sizeInput: function() {
    var width = this.input.clientWidth;
    this.input.style.width = '0px';
    this.input.style.marginLeft = width + 'px';
    this.input.style.width = this.input.scrollWidth + 20;
    this.input.style.marginLeft = '';
  }
};

jSlim.ready(function() {
  jSlim.all('.tag-editor', function(a) {
    new TagEditor(a);
  });
});

export { TagEditor };
