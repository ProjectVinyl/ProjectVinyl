var TagEditor = (function() {
  function namespace(name) {
    if (name.indexOf(':') != -1) return name.split(':')[0];
    return '';
  }

  function createTagItem(ed, tag) {
    var item = $('<li class="tag tag-' + tag.namespace + '" data-slug="' + tag.slug + '"><i title="Remove Tag" data-name="' + tag.name + '" class="fa fa-times remove"></i><a href="/tags/' + tag.link + '">' + tag.name + '</a></li>');
    ed.list.append(item);
    item.find('.remove').on('click', function(e) {
      ed.removeTag(item, tag);
      e.stopPropagation();
    });
  }

  function createDisplayTagItem(tag) {
    return '<li class="tag tag-' + tag.namespace + ' drop-down-holder popper" data-slug="' + tag.slug + '">\
      <a href="/tags/' + tag.link + '"><span>' + tag.name + '</span>' + (tag.members > -1 ? ' (' + tag.members + ')' : '') + '</a>\
      <ul class="drop-down pop-out">\
        <li class="action toggle" data-family="tag-flags" data-descriminator="hide" data-action="hide" data-target="tag" data-id="' + name + '">\
          <span class="icon">\
          </span>\
            <span class="label">Hide</span>\
        </li>\
        <li class="action toggle" data-family="tag-flags" data-descriminator="spoiler" data-action="spoiler" data-target="tag" data-id="' + name + '">\
          <span class="icon">\
          </span>\
            <span class="label">Spoiler</span>\
        </li>\
        <li class="action toggle" data-family="tag-flags" data-descriminator="watch" data-action="watch" data-target="tag" data-id="' + name + '">\
          <span class="icon">\
          </span>\
            <span class="label">Watch</span>\
        </li>\
      </ul>\
    </li>';
  }

  function BakedArray(arr) {
    if (arr && arr.baked) return arr;
    arr = arr || [];
    arr.baked = function() {
      var result = [];
      for (var i = this.length; i--;) result.unshift(this[i].toString());
      return result;
    };
    arr.join = function(splitter) {
      return Array.prototype.join.apply(this.baked(), arguments);
    };
    arr.indexOf = function(e, i) {
      var result = Array.prototype.indexOf.apply(this, arguments);
      return result > -1 ? result : Array.prototype.indexOf.call(this.baked(), e.toString(), i);
    };
    return arr;
  }

  function Tag(name) {
    var ans = name.name ? name : {
      namespace: namespace(name),
      name: name,
      members: -1,
      link: name
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

  function TagEditor(el) {
    var self = this;
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

    var last_value = '';
    var handled_back = false;
    this.input.on('keydown', function(e) {
      if (e.which == Key.ENTER || e.which == Key.COMMA) {
        var text = self.input.val().trim().split(/,|;/);
        for (var i = 0; i < text.length; i++) {
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
          var value = self.input.val();
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
    this.input.on('keyup', function() {
      self.sizeInput();
      handled_back = false;
    }).on('mousedown', function(e) {
      e.stopPropagation();
    });
    var autocomplete = null;
    this.input.on('focus', function(e) {
      if (!autocomplete) {
        autocomplete = setInterval(function() {
          var value = self.input.val();
          if (value != last_value) {
            last_value = value;
            self.doSearch(value.trim().split(/,|;/).reverse()[0]);
          }
        }, 1000);
      }
      self.dom.addClass('focus');
    });
    this.input.on('blur', function() {
      clearInterval(autocomplete);
      autocomplete = null;
      self.dom.removeClass('focus');
    });
    el.on('mouseup', function(e) {
      self.input.focus();
      e.preventDefault();
      e.stopPropagation();
    }).on('mousedown', function(e) {
      e.stopPropagation();
    });
  }

  TagEditor.getOrCreate = function(el) {
    el = $(el);
    if (el[0].getTagEditorObj) return el[0].getTagEditorObj();
    return new TagEditor(el);
  };

  TagEditor.prototype = {
    loadTags: function(tags) {
      if (tags.length) {
        this.tags = tags.split ? tags.split(',') : tags;
        for (var i = 0; i < this.tags.length; i++) {
          this.tags[i] = Tag(this.tags[i]);
        }
      } else {
        this.tags = [];
      }
      BakedArray(this.tags);
      var me = this;
      var unloaded_slugs = BakedArray();
      unloaded_slugs.push.apply(unloaded_slugs, this.tags);
      this.list.find('li i.remove').each(function() {
        var li = $(this);
        var name = li.attr('data-name');
        var index = unloaded_slugs.indexOf(name);
        if (index < 0) {
          li.parent().remove();
        } else {
          var item = unloaded_slugs.splice(index, 1)[0];
          li.on('click', function(e) {
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
    appendTag: function(tag) {
      tag = Tag(tag);
      if (tag.name.length && tag.name.indexOf('uploader:') != 0 && tag.name.indexOf('title:') != 0) {
        if (this.tags.indexOf(tag) == -1) {
          this.pickupTag(tag);
          this.history.unshift({type: 1, tag: tag});
          this.future.length = 0;
        }
      }
    },
    pickupTag: function(tag) {
      tag = Tag(tag);
      this.tags.push(tag);
      this.value.val(this.tags.join(','));
      createTagItem(this, tag);
    },
    removeTag: function(self, tag) {
      tag = Tag(tag);
      this.dropTag(self, tag);
      this.history.unshift({type: -1, tag: tag});
      this.future.length = 0;
    },
    dropTag: function(self, tag) {
      this.tags.splice(this.tags.indexOf(tag), 1);
      self.remove();
      this.value.val(this.tags.join(','));
      this.save();
    },
    undo: function() {
      if (this.history.length) {
        var item = this.history.shift();
        this.future.unshift(item);
        if (item.type > 0) {
          this.dropTag(this.list.find('[data-name="' + item.tag.name + '"]').parent(), item.tag);
        } else {
          this.pickupTag(item.tag);
          this.save();
        }
      }
    },
    redo: function() {
      if (this.future.length) {
        var item = this.future.shift();
        this.history.unshift(item);
        if (item.type > 0) {
          this.pickupTag(item.tag);
          this.save();
        } else {
          this.dropTag(this.list.find('[data-name="' + item.tag.name + '"]').parent(), item.tag);
        }
      }
    },
    reload: function(tags) {
      this.tags.length = 0;
      this.list.empty();
      if (this.norm) this.norm.html('');
      for (var i = 0; i < tags.length; i++) {
        var tag = Tag(tags[i]);
        this.tags.unshift(tag);
        createTagItem(this, tag);
        if (this.norm) {
          this.norm.append(createDisplayTagItem(tag));
        }
      }
      this.value.val(this.tags.join(','));
    },
    save: function() {
      this.dom.trigger('tagschange');
      if (this.target && this.id) {
        var me = this;
        ajax.post('update/' + this.target, function(json) {
          me.reload(json.results);
        }, false, {
          id: id,
          field: 'tags',
          value: this.value.val()
        });
      } else if (this.norm) {
        this.norm.html('');
        for (var i = 0; i < this.tags.length; i++) {
          this.norm.append(createDisplayTagItem(this.tags[i]));
        }
      }
    },
    sizeInput: function() {
      var width = this.input.width();
      this.input.css('width', 0);
      this.input.css('margin-left', width);
      this.input.css('width', this.input[0].scrollWidth + 20);
      this.input.css('margin-left', '');
    },
    doSearch: function(name) {
      var me = this;
      name = name.toLowerCase();
      if (name.length <= 0) {
        me.dom.removeClass('pop-out-shown');
        return;
      }
      ajax.get('find/tags', function(json) {
        me.searchResults.empty();
        for (var i = json.results.length; i--;) {
          var item = $('<li class="tag-' + json.results[i].namespace + '"><span>' + json.results[i].name.replace(name, '<b>' + name + '</b>') + '</span> (' + json.results[i].members + ')' + '</li>');
          item[0].tag = json.results[i];
          item.on('click', function() {
            me.dom.removeClass('pop-out-shown');
            var text = me.input.val().trim().split(/,|;/);
            text.pop();
            for (var i = 0; i < text.length; i++) {
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
})();

$(function() {
  $('.tag-editor').each(function() {
    new TagEditor(this);
  });
});