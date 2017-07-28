function TextNode(content) {
  this.text = content;
}
TextNode.prototype = {
  innerTEXT: function() {
    return escapeHTML(this.text);
  },
  outerHTML: function() {
    var result = this.innerTEXT();
    result = result.replace(/\n/g, '<br>');
    return result;
  },
  outerBBC: function() {
    return this.innerTEXT();
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
          if (text.length) this.appendTEXT(text);
          return content.substring(index + (open + '/' + this.tagName + close).length, content.length);
        }
        
        if (content[index] == '@' || content[index] == ':' || content[index] == open) {
          if (text.length) {
            this.appendTEXT(text);
            text = '';
          }
          if (content[index] == '@') {
            content = this.parseAtTag(content.substring(index + 1, content.length));
          } else if (content[index] == ':') {
            var result;
            if (result = this.parseEmoticonAlias(content.substring(index, content.length))) {
              content = result;
            } else {
              text += content[index];
              continue;
            }
          } else if (content[index] == open) {
            this.appendNode().parse(content.substring(index, content.length), open, close);
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
        
        if (tagName.length && content[index] == '=') {
          content = this.parseEqualsPar(content.substring(index + 1, content.length), close);
          index = -1;
        } else if (tagName.length && (content[index] == close || content[index] == '/' || content[index] == ' ')) {
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
    
    if (text.length) this.appendTEXT(text);
    return content.substring(index + 1, content.length);
  },
  appendNode: function(tagName) {
    var tag = new Node(this);
    tag.tagName = tagName;
    this.children.push(tag);
    return tag;
  },
  appendTEXT: function(text) {
    if (text.length) this.children.push(new TextNode(text));
  },
  parseTagName: function(tag) {
    this.tagName = tag.split('=')[0].trim();
    if (this.tagName.replace(/[^a-zA-Z0-9]/g, '') != this.tagName) {
      this.tagName = '';
    }
  },
  parseEqualsPar(content, close) {
    var index = -1;
    var quote = null;
    var par = '';
    
    while (index < content.length - 1) {
      index++;
      
      if (quote != null) {
        if (content[index] == quote) {
          quote = null;
          continue;
        }
      } else {
        if (content[index] == '"' || content[index] == "'") {
          quote = content[index];
          continue;
        }
          
        if (content[index] == ' ' || content[index] == close) {
          if (par.length) {
            this.equalsPar = par;
          }
          return content.substring(index, content.length);
        }
      }
      
      par += content[index];
    }
    
    if (par.length) {
      this.equalsPar = par;
    }
    return content.substring(index, content.length);
  },
  parseAtTag: function(content) {
    var atTag = content.split(/[\s\[\<]/)[0];
    this.appendNode('@').appendTEXT(atTag);
    return content.replace(atTag, '');
  },
  parseEmoticonAlias: function(content) {
    var emote = content.split(':');
    if (emote.length > 1) {
      emote = emote[1];
      if (emoticons.indexOf(emote) > -1) {
        this.appendNode('emote').appendTEXT(emote);
        return content.replace(':' + emote + ':', '');
      }
    }
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
  innerTEXT: function(tag) {
    var text = '';
    this.children.forEach(function(child) {
      text += child.innerTEXT();
    });
    return text;
  },
  innerHTML: function(tag) {
    var html = '';
    this.children.forEach(function(child) {
      html += child.outerHTML();
    });
    return html;
  },
  innerBBC: function(tag) {
    var html = '';
    this.children.forEach(function(child) {
      html += child.outerBBC();
    });
    return html;
  },
  outerHTML: function() {
    var gen = getTagGenerator(this.tagName, 'html');
    return gen ? gen(this) : '';
  },
  outerBBC: function() {
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

function escapeHTML(string) {
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
      return tag.innerBBC();
    },
    html: function(tag) {
      if (tag.tagName == '@') {
        return '<a class="user-link data-id="0" href="/">' + tag.innerTEXT() + '</a>';
      }
      if (tag.tagName.indexOf('yt') == 0 && !tag.tagName.replace('yt', '').match(/[^a-zA-z0-9\-_]/)) {
        return '<iframe allowfullscreen class="embed" src="https://www.youtube.com/embed/' + tag.tagName.replace('yt', '') + '"></iframe>' + tag.innerHTML();
      }
      if (tag.tagName.length && !tag.tagName.match(/[^0-9]/)) {
        return '<iframe allowfullscreen class="embed" src="/embed/' + tag.tagName + '"></iframe>' + tag.innerHTML();
      }
      return tag.innerHTML();
    }
  },
  bbc: [
    {
      match: ['br'],
      func: function(tag) {
        return '\n' + tag.innerBBC();
      }
    },
    {
      match: ['hr'],
      func: function(tag) {
        return '[hr]' + tag.innerBBC();
      }
    },
    {
      match: ['b','u','s','sup','sub'],
      func: function(tag) {
        return '[' + tag.tagName + ']' + tag.innerBBC() + '[/' + tag.tagName + ']';
      }
    },
    {
      match: ['i'],
      func: function(tag) {
        if (tag.attributes.class && tag.attributes.class.indexOf('fa fa-fw fa-') == 0) {
          return '[icon]' + tag.attributes.class.replace('fa fa-fw fa-', '').split(/[^a-zA-Z0-9]/)[0] + '[/icon]';
        }
        return '[' + tag.tagName + ']' + tag.innerBBC() + '[/' + tag.tagName + ']';
      }
    },
    {
      match: ['blockquote'],
      func: function(tag) {
        return '[q]' + tag.innerBBC() + '[/q]';
      }
    },
    {
      match: ['@'],
      func: function(tag) {
        return tag.tagName + tag.innerTEXT();
      }
    },
    {
      match: ['a'],
      func: function(tag) {
        if (!tag.attributes.href) {
          return tag.innerBBC();
        }
        if (tag.classes.indexOf('user-link') > -1) {
          return '@' + tag.innerTEXT();
        }
        if (tag.attributes['data-link']) {
          if (tag.attributes['data-link'] == '1') {
            return tag.attributes['href'];
          }
          if (tag.attributes['data-link'] == '2') {
            return '&gt;&gt;' + tag.attributes.href.replace('#comment_', '');
          }
        }
        return '[url=' + tag.attributes.href + ']' + tag.innerBBC() + '[/url]';
      }
    },
    {
      match: ['div'],
      func: function(tag) {
        if (tag.classes.indexOf('spoiler') < 0) {
          return tag.innerBBC();
        }
        return '[spoiler]' + tag.innerBBC() + '[/spoiler]';
      }
    },
    {
      match: ['img'],
      func: function(tag) {
        if (tag.attributes.class == 'emoticon' && tag.attributes.src) {
          return ':' + tag.attributes.src.replace('/emoticons/([^a-zA-Z0-9]+).png', '$1') + ':';
        }
        return '[img]' + (tag.attributes.src || '') + '[img]' + tag.innerBBC();
      }
    },
    {
      match: ['emote'],
      func: function(tag) {
        return ':' + tag.innerTEXT() + ':';
      }
    },
    {
      match: ['iframe'],
      func: function(tag) {
        if (tag.attributes.src && tag.attributes.class == 'embed') {
          if (tag.attributes.src.indexOf('youtube') > -1) {
            return '[yt' + ytId(tag.attributes.src) + ']' + tag.innerBBC();
          }
          return '[' + tag.attributes.src.replace(/[^0-9]/g,'') + ']' + tag.innerBBC();
        }
        return tag.innerBBC();
      }
    }
  ],
  html: [
    {
      match: ['b','i','u','s','sup','sub','hr'],
      func: function(tag) {
        return '<' + tag.tagName + '>' + tag.innerHTML() + '</' + tag.tagName + '>';
      }
    },
    {
      match: ['icon'],
      func: function(tag) {
        return '<i class="fa fa-fw fa-' + tag.innerTEXT().split(/[^a-zA-Z0-9]/)[0] + '"></' + tag.tagName + '>';
      }
    },
    {
      match: ['q'],
      func: function(tag) {
        return '<blockquote' + (!tag.odd() ? ' class="even"' : '') + '>' + tag.innerHTML() + '</blockquote>';
      }
    },
    {
      match: ['url'],
      func: function(tag) {
        if (tag.equalsPar) {
          return '<a href="' + tag.equalsPar + '">' + tag.innerHTML() + '</a>';
        }
        return '<a href="' + tag.innerTEXT() + '">' + tag.innerTEXT() + '</a>';
      }
    },
    {
      match: ['spoiler'],
      func: function(tag) {
        return '<div class="spoiler">' + tag.innerHTML() + '</div>';
      }
    },
    {
      match: ['img'],
      func: function(tag) {
        return '<img src="' + tag.innerTEXT().replace(/['"]/g,'') + '"></img>';
      }
    },
    {
      match: ['emote'],
      func: function(tag) {
        return '<img src="/emoticons/' + tag.innerTEXT() + '.png"></img>';
      }
    }
  ]
};

export const BBCode = {
  fromHTML: function(html) {
    return Node.parse(html, '<', '>');
  },
  fromBBC: function(bbc) {
    return Node.parse(bbc, '[', ']');
  }
};