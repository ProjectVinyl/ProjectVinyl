const TagEditor = (function() {
  function namespace(name) {
    if (name.indexOf(':') != -1) return name.split(':')[0];
    return '';
  }

  function createTagItem(ed, tag) {
    const item = $(`<li class="tag tag-${tag.namespace}" data-slug="${tag.slug}"><i title="Remove Tag" data-name="${tag.name}" class="fa fa-times remove"></i><a href="/tags/${tag.link}">${tag.name}</a></li>`);
    ed.list.append(item);
    item.find('.remove').on('click', e => {
      ed.removeTag(item, tag);
      e.stopPropagation();
    });
  }

  function createDisplayTagItem(tag) {
    return `<li class="tag tag-${tag.namespace} drop-down-holder popper" data-slug="${tag.slug}">\
      <a href="/tags/${tag.link}"><span>${tag.name}</span>${tag.members > -1 ? ` (${tag.members})` : ''}</a>\
      <ul class="drop-down pop-out">\
        <li class="action toggle" data-family="tag-flags" data-descriminator="hide" data-action="hide" data-target="tag" data-id="${name}">\
          <span class="icon">\
          </span>\
            <span class="label">Hide</span>\
        </li>\
        <li class="action toggle" data-family="tag-flags" data-descriminator="spoiler" data-action="spoiler" data-target="tag" data-id="${name}">\
          <span class="icon">\
          </span>\
            <span class="label">Spoiler</span>\
        </li>\
        <li class="action toggle" data-family="tag-flags" data-descriminator="watch" data-action="watch" data-target="tag" data-id="${name}">\
          <span class="icon">\
          </span>\
            <span class="label">Watch</span>\
        </li>\
      </ul>\
    </li>`;
  }

  function BakedArray(arr) {
    if (arr && arr.baked) return arr;
    arr = arr || [];
    arr.baked = function() {
      const result = [];
      for (let i = this.length; i--;) result.unshift(this[i].toString());
      return result;
    };
    arr.join = function(splitter) {
      return Array.prototype.join.apply(this.baked(), arguments);
    };
    arr.indexOf = function(e, i) {
      const result = Array.prototype.indexOf.apply(this, arguments);
      return result > -1 ? result : Array.prototype.indexOf.call(this.baked(), e.toString(), i);
    };
    return arr;
  }

  function Tag(name) {
    const ans = name.name ? name : {
      namespace: namespace(name),
      name,
      members: -1,
      link: name
    };
    ans.slug = ans.name.replace(`${ans.namespace}:`, '');
    ans.toString = function() {
      return this.name;
    };
    ans.valueOf = function() {
      return this.toString().valueOf();
    };
    return ans;
  }

  function TagEditor(el) {
    const self = this;
    this.history = [];
    this.future = [];
    el = $(el);
    el.find('.values').remove();
    el[0].getActiveTagsArray = function() {
      return self.tags;
    };
    el[0].getTagEditorObj = function() {
      return self;
    };
    this.dom = el;
    this.input = el.find('.input');
    this.value = el.find('.value textarea');
    this.list = el.find('ul.tags');
    this.searchResults = el.find('.search-results');
    this.tags = this.value.val().replace(/,,|^,|,$/g, '');
    this.target = this.value.attr('data-target');
    this.id = this.value.attr('data-id');
    this.norm = null;
    if (el.parent().hasClass('editing')) {
      this.norm = el.parent().parent().find('.normal.tags');
    }
    this.loadTags(this.tags);

    let last_value = '';
    let handled_back = false;
    this.input.on('keydown', e => {
      if (e.which == Key.ENTER || e.which == Key.COMMA) {
        const text = self.input.val().trim().split(/,|;/);
        for (let i = 0; i < text.length; i++) {
          self.appendTag(text[i]);
        }
        self.input.val('');
        self.save();
        e.preventDefault();
        e.stopPropagation();
        handled_back = false;
      } else if (e.which == Key.BACKSPACE) {
        if (!handled_back) {
          handled_back = true;
          const value = self.input.val();
          if (!value.length) {
            self.list.children('.tag').last().find('.remove').click();
          }
        }
      } else if (e.ctrlKey) {
        if (e.which == Key.Z) {
          self.undo();
          e.preventDefault();
          e.stopPropagation();
        } else if (e.which == Key.Y) {
          self.redo();
          e.preventDefault();
          e.stopPropagation();
        }
        handled_back = false;
      } else {
        handled_back = false;
      }
      self.sizeInput();
    });
    this.input.on('keyup', () => {
      self.sizeInput();
      handled_back = false;
    }).on('mousedown', e => {
      e.stopPropagation();
    });
    let autocomplete = null;
    this.input.on('focus', e => {
      if (!autocomplete) {
        autocomplete = setInterval(() => {
          const value = self.input.val();
          if (value != last_value) {
            last_value = value;
            self.doSearch(value.trim().split(/,|;/).reverse()[0]);
          }
        }, 1000);
      }
      self.dom.addClass('focus');
    });
    this.input.on('blur', () => {
      clearInterval(autocomplete);
      autocomplete = null;
      self.dom.removeClass('focus');
    });
    el.on('mouseup', e => {
      self.input.focus();
      e.preventDefault();
      e.stopPropagation();
    }).on('mousedown', e => {
      e.stopPropagation();
    });
  }

  TagEditor.getOrCreate = function(el) {
    el = $(el);
    if (el[0].getTagEditorObj) return el[0].getTagEditorObj();
    return new TagEditor(el);
  };

  TagEditor.prototype = {
    loadTags(tags) {
      if (tags.length) {
        this.tags = tags.split ? tags.split(',') : tags;
        for (var i = 0; i < this.tags.length; i++) {
          this.tags[i] = Tag(this.tags[i]);
        }
      } else {
        this.tags = [];
      }
      BakedArray(this.tags);
      const me = this;
      const unloaded_slugs = BakedArray();
      unloaded_slugs.push.apply(unloaded_slugs, this.tags);
      this.list.find('li i.remove').each(function() {
        const li = $(this);
        const name = li.attr('data-name');
        const index = unloaded_slugs.indexOf(name);
        if (index < 0) {
          li.parent().remove();
        } else {
          const item = unloaded_slugs.splice(index, 1)[0];
          li.on('click', e => {
            me.removeTag(li.parent(), item);
            e.stopPropagation();
          });
          item.namespace = li.parent().attr('data-namespace');
        }
      });
      for (var i = 0; i < unloaded_slugs.length; i++) {
        createTagItem(this, unloaded_slugs[i]);
      }
      this.value.val(this.tags.join(','));
    },
    appendTag(tag) {
      tag = Tag(tag);
      if (tag.name.length && tag.name.indexOf('uploader:') != 0 && tag.name.indexOf('title:') != 0) {
        if (this.tags.indexOf(tag) == -1) {
          this.pickupTag(tag);
          this.history.unshift({type: 1, tag});
          this.future.length = 0;
        }
      }
    },
    pickupTag(tag) {
      tag = Tag(tag);
      this.tags.push(tag);
      this.value.val(this.tags.join(','));
      createTagItem(this, tag);
    },
    removeTag(self, tag) {
      tag = Tag(tag);
      this.dropTag(self, tag);
      this.history.unshift({type: -1, tag});
      this.future.length = 0;
    },
    dropTag(self, tag) {
      this.tags.splice(this.tags.indexOf(tag), 1);
      self.remove();
      this.value.val(this.tags.join(','));
      this.save();
    },
    undo() {
      if (this.history.length) {
        const item = this.history.shift();
        this.future.unshift(item);
        if (item.type > 0) {
          this.dropTag(this.list.find(`[data-name="${item.tag.name}"]`).parent(), item.tag);
        } else {
          this.pickupTag(item.tag);
          this.save();
        }
      }
    },
    redo() {
      if (this.future.length) {
        const item = this.future.shift();
        this.history.unshift(item);
        if (item.type > 0) {
          this.pickupTag(item.tag);
          this.save();
        } else {
          this.dropTag(this.list.find(`[data-name="${item.tag.name}"]`).parent(), item.tag);
        }
      }
    },
    reload(tags) {
      this.tags.length = 0;
      this.list.empty();
      if (this.norm) this.norm.html('');
      for (let i = 0; i < tags.length; i++) {
        const tag = Tag(tags[i]);
        this.tags.unshift(tag);
        createTagItem(this, tag);
        if (this.norm) {
          this.norm.append(createDisplayTagItem(tag));
        }
      }
      this.value.val(this.tags.join(','));
    },
    save() {
      this.dom.trigger('tagschange');
      if (this.target && this.id) {
        const me = this;
        ajax.post(`update/${this.target}`, json => {
          me.reload(json.results);
        }, false, {
          id,
          field: 'tags',
          value: this.value.val()
        });
      } else if (this.norm) {
        this.norm.html('');
        for (let i = 0; i < this.tags.length; i++) {
          this.norm.append(createDisplayTagItem(this.tags[i]));
        }
      }
    },
    sizeInput() {
      const width = this.input.width();
      this.input.css('width', 0);
      this.input.css('margin-left', width);
      this.input.css('width', this.input[0].scrollWidth + 20);
      this.input.css('margin-left', '');
    },
    doSearch(name) {
      const me = this;
      name = name.toLowerCase();
      if (name.length <= 0) {
        me.dom.removeClass('pop-out-shown');
        return;
      }
      ajax.get('find/tags', json => {
        me.searchResults.empty();
        for (let i = json.results.length; i--;) {
          const item = $(`<li class="tag-${json.results[i].namespace}"><span>${json.results[i].name.replace(name, `<b>${name}</b>`)}</span> (${json.results[i].members})` + '</li>');
          item[0].tag = json.results[i];
          item.on('click', function() {
            me.dom.removeClass('pop-out-shown');
            const text = me.input.val().trim().split(/,|;/);
            text.pop();
            for (let i = 0; i < text.length; i++) {
              me.appendTag(text[i]);
            }
            me.appendTag(this.tag);
            me.input.val('');
            me.sizeInput();
            me.save();
          });
          me.searchResults.append(item);
        }
        me.dom[json.results.length ? 'addClass' : 'removeClass']('pop-out-shown');
      }, {
        q: name
      });
    }
  };

  return TagEditor;
}());

$(() => {
  $('.tag-editor').each(function() {
    new TagEditor(this);
  });
});
