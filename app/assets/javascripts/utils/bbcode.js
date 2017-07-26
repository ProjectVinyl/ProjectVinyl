function TextNode(content) {
  this.text = content;
}
TextNode.prototype = {
  innerText: function() {
    return escapeHtml(this.text);
  },
  outerHtml: function() {
    var result = this.innerText();
    result = result.replace(/\n/g, '<br>');
    return result;
  },
  outerBbc: function() {
    return this.innerText();
  }
};

function Node(parent) {
  this.tagName = '';
  this.children = [];
  this.attributes = {};
  this.classes = [];
  this.parent = parent;
}

Node.parse = function(text, open, close) {
  var result = new Node();
  result.tagName = 'Document';
  result.parse(open + result.tagName + close + text + open + '/' + result.tagName + close, open, close);
  return result;
}

Node.prototype = {
  parse: function(content, open, close) {
    var index = -1;
    var state = -1;
    var tagName = '';
    var text = '';
    var quote = null;
    
    while (index < content.length - 1) {
      index++;
      
      if (state == 1) {
        if (this.tagName == 'br' || this.tagName == 'img') {
          if (content[index] == '/') index++;
          if (content[index] == close) index++;
          return content.substring(index, content.length);
        }
        
        if (content.indexOf('/' + close) == 0) {
          return content.substring(3, content.length);
        }
        
        if (content.indexOf(open + '/' + this.tagName + close) == index) {
          if (text.length) this.appendText(text);
          return content.substring(index + (open + '/' + this.tagName + close).length, content.length);
        }
        
        if (content[index] == '@' || content[index] == ':' || content[index] == open) {
          if (text.length) {
            this.appendText(text);
            text = '';
          }
          if (content[index] == '@') {
            content = this.parseAtTag(content.substring(index + 1, content.length));
          } else if (content[index] == ':') {
            content = this.parseEmoticonAlias(content.substring(index, content.length));
          } else if (content[index] == open) {
            var child = new Node(this);
            this.children.push(child);
            content = child.parse(content.substring(index, content.length), open, close);
          }
          index = -1;
          continue;
        }
        text += content[index];
      }
      
      if (state == 0) {
        if (quote != null) {
          if (content[index] == quote) {
            quote = null;
            continue;
          }
          tagName += content[index];
          continue;
        }
        
        if (content[index] == '"' || content[index] == "'") {
          quote = content[index];
          continue;
        }
        
        if (tagName.length && (content[index] == close || content[index] == '/' || content[index] == ' ')) {
          if (content[index] == close || content[index] == '/') {
            this.parseTagName(tagName);
          }
          
          if (content[index] == ' ') {
            content = this.parseAttributes(content.substring(index + 1, content.length), close);
            index = -1;
          }
          
          state = 1;
        } else {
          tagName += content[index];
        }
      }
      
      if (state == -1) {
        if (content[index] == open) {
          state = 0;
        }
      }
    }
    
    if (text.length) this.appendText(text);
    return content.substring(index + 1, content.length);
  },
  appendNode: function(tagName) {
    var tag = new Node(this);
    tag.tagName = tagName;
    this.children.append(tag);
    return tag;
  },
  appendText: function(text) {
    if (text.length) this.children.push(new TextNode(text));
  },
  parseTagName: function(tag) {
    this.tagName = tag.split('=')[0].trim();
    if (tag.indexOf('=') > -1) {
      this.equalsPar = tag.replace(this.tagName + '=', '');
    }
    if (this.tagName.replace(/[^a-zA-Z0-9]/g, '') != this.tagName) {
      this.tagName = '';
    }
  },
  parseAtTag: function(content) {
    var atTag = content.split(/[\s\[\<]/)[0];
    this.appendNode('@').appendText(atTag);
    return content.replace(atTag, '');
  },
  parseEmoticonAlias: function(content) {
    var emote = content.split(':');
    if (emote.length > 1) {
      emote = emote[1];
      if (emoticons.indexOf(emote) > -1) {
        this.appendNode('emote').appendText(emote);
      }
    }
    return content;
  },
  parseAttributes: function(content, close) {
    var index = -1;
    var quote = null;
    var name = '';
    var value = '';
    var inValue = false;
    while (index < content.length - 1) {
      index++;
      if (!inValue || quote == null) {
        if (content[index] == '/' && index < content.length - 1 && content[index + 1] == close) {
          return content.substring(index, content.length);
        }
        if (content[index] == close) {
          if (name.length) this.attributes[name.trim()] = value;
          return content.substring(index + 1, content.length);
        }
      }
      if (!inValue) {
        if (content[index] == '=') {
          inValue = true;
          continue;
        }
        name += content[index];
      } else {
        if (quote == null) {
          if (content[index] == '"' || content[index] == "'") {
            quote = content[index];
            continue;
          }
          if (content[index] == ' ') {
            this.setAttribute(name.trim(), value);
            name = '';
            value = '';
            inValue = false;
            continue;
          }
        } else if (content[index] == quote) {
          quote = null;
          this.setAttribute(name, value);
          name = '';
          value = '';
          inValue = false;
          continue;
        }
        value += content[index];
      }
    }
    return content.substring(index + 1, content.length);
  },
  setAttribute: function(name, value) {
    name = name.trim();
    this.attributes[name] = value;
    if (name == 'class') {
      this.classes = value.split(/\s/);
    }
  },
  innerText: function(tag) {
    var text = '';
    this.children.forEach(function(child) {
      text += child.innerText();
    });
    return text;
  },
  innerHtml: function(tag) {
    var html = '';
    this.children.forEach(function(child) {
      html += child.outerHtml();
    });
    return html;
  },
  innerBbc: function(tag) {
    var html = '';
    this.children.forEach(function(child) {
      html += child.outerBbc();
    });
    return html;
  },
  outerHtml: function() {
    var gen = getTagGenerator(this.tagName, 'html');
    return gen ? gen(this) : '';
  },
  outerBbc: function() {
    var gen = getTagGenerator(this.tagName, 'bbc');
    return gen ? gen(this) : '';
  },
  depth: function() {
    if (!this.parent) return 0;
    return this.parent.depth() + 1;
  },
  odd: function() {
    return this.depth() % 2 == 1;
  }
};
  
function ytId(url) {
  if (url.indexOf('v=')) return url.split('v=')[1].split('&')[0];
  return url.split('?')[0].split('/').reverse()[0];
}

function escapeHtml(string) {
  return string.replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function getTagGenerator(tag, type) {
  var result = null;
  if (!tag.length) {
    return tagGenerators.default[type];
  }
  tagGenerators[type].forEach(function(item) {
    if (item.match.indexOf(tag) > -1) {
      result = item.func;
    }
  });
  return result || tagGenerators.default[type];
}

var tagGenerators = {
  default: {
    bbc: function(tag) {
      return tag.innerBbc();
    },
    html: function(tag) {
      if (tag.tagName == '@') {
        return '<a class="user-link data-id="0" href="/">' + tag.innerText() + '</a>';
      }
      if (tag.tagName.indexOf('yt') == 0 && !tag.tagName.replace('yt', '').match(/[^a-zA-z0-9\-_]/)) {
        return '<iframe allowfullscreen class="embed" src="https://www.youtube.com/embed/' + tag.tagName.replace('yt', '') + '"></iframe>' + tag.innerHtml();
      }
      if (tag.tagName.length && !tag.tagName.match(/[^0-9]/)) {
        return '<iframe allowfullscreen class="embed" src="/embed/' + tag.tagName + '"></iframe>' + tag.innerHtml();
      }
      return tag.innerHtml();
    }
  },
  bbc: [
    {
      match: ['br'],
      func: function(tag) {
        return '\n' + tag.innerBbc();
      }
    },
    {
      match: ['hr'],
      func: function(tag) {
        return '[hr]' + tag.innerBbc();
      }
    },
    {
      match: ['b','u','s','sup','sub'],
      func: function(tag) {
        return '[' + tag.tagName + ']' + tag.innerBbc() + '[/' + tag.tagName + ']';
      }
    },
    {
      match: ['i'],
      func: function(tag) {
        if (tag.attributes.class && tag.attributes.class.indexOf('fa fa-fw fa-') == 0) {
          return '[icon]' + tag.attributes.class.replace('fa fa-fw fa-', '').split(/[^a-zA-Z0-9]/)[0] + '[/icon]';
        }
        return '[' + tag.tagName + ']' + tag.innerBbc() + '[/' + tag.tagName + ']';
      }
    },
    {
      match: ['blockquote'],
      func: function(tag) {
        return '[q]' + tag.innerBbc() + '[/q]';
      }
    },
    {
      match: ['@'],
      func: function(tag) {
        return tag.tagName + tag.innerText();
      }
    },
    {
      match: ['a'],
      func: function(tag) {
        if (!tag.attributes.href) {
          return tag.innerBbc();
        }
        if (tag.classes.indexOf('user-link') > -1) {
          return '@' + tag.innerText();
        }
        if (tag.attributes['data-link']) {
          if (tag.attributes['data-link'] == '1') {
            return tag.attributes['href'];
          }
          if (tag.attributes['data-link'] == '2') {
            return '&gt;&gt;' + tag.attributes.href.replace('#comment_', '');
          }
        }
        return '[url=' + tag.attributes.href + ']' + tag.innerBbc() + '[/url]';
      }
    },
    {
      match: ['div'],
      func: function(tag) {
        if (tag.classes.indexOf('spoiler') < 0) {
          return tag.innerBbc();
        }
        return '[spoiler]' + tag.innerBbc() + '[/spoiler]';
      }
    },
    {
      match: ['img'],
      func: function(tag) {
        if (tag.attributes.class == 'emoticon' && tag.attributes.src) {
          return ':' + tag.attributes.src.replace('/emoticons/([^a-zA-Z0-9]+).png', '$1') + ':';
        }
        return '[img]' + (tag.attributes.src || '') + '[img]' + innerBbc(tag);
      }
    },
    {
      match: ['emote'],
      func: function(tag) {
        return ':' + tag.innerText() + ':';
      }
    },
    {
      match: ['iframe'],
      func: function(tag) {
        if (tag.attributes.src && tag.attributes.class == 'embed') {
          if (tag.attributes.src.indexOf('youtube') > -1) {
            return '[yt' + ytId(tag.attributes.src) + ']' + innerBbc(tag);
          }
          return '[' + tag.attributes.src.replace(/[^0-9]/g,'') + ']' + innerBbc(tag);
        }
        return innerBbc(tag);
      }
    }
  ],
  html: [
    {
      match: ['b','i','u','s','sup','sub','hr'],
      func: function(tag) {
        return '<' + tag.tagName + '>' + tag.innerHtml() + '</' + tag.tagName + '>';
      }
    },
    {
      match: ['icon'],
      func: function(tag) {
        return '<i class="fa fa-fw fa-' + tag.innerText().split(/[^a-zA-Z0-9]/)[0] + '"></' + tag.tagName + '>';
      }
    },
    {
      match: ['q'],
      func: function(tag) {
        return '<blockquote' + (!tag.odd() ? ' class="even"' : '') + '>' + tag.innerHtml() + '</blockquote>';
      }
    },
    {
      match: ['url'],
      func: function(tag) {
        if (tag.equalsPar) {
          return '<a href="' + tag.equalsPar + '">' + tag.innerHtml() + '</a>';
        }
        return '<a href="' + tag.innerText() + '">' + tag.innerText() + '</a>';
      }
    },
    {
      match: ['spoiler'],
      func: function(tag) {
        return '<div class="spoiler">' + tag.innerHtml() + '</div>';
      }
    },
    {
      match: ['img'],
      func: function(tag) {
        return '<img src="' + tag.innerText().replace(/['"]/g,'') + '"></img>';
      }
    },
    {
      match: ['emote'],
      func: function(tag) {
        return '<img src="/emoticons/' + tag.innerText() + '.png"></img>';
      }
    }
  ]
};

export const BBCode = {
  fromHtml: function(html) {
    return Node.parse(html, '<', '>');
  },
  fromBbc: function(bbc) {
    return Node.parse(bbc, '[', ']');
  }
};