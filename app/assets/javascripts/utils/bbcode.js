function TextNode(content) {
  this.text = content;
}
TextNode.prototype = {
  innerTEXT: function() {
    return escapeHTML(this.text);
  },
  inner: function(type) {
    return this.outer(type);
  },
  outer: function(type) {
    return this.innerTEXT();
  },
  outerHTML: function() {
    return this.outer('html');
  },
  outerBBC: function() {
    return this.outer('bbc');
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
  const result = new Node();
  result.tagName = 'Document';
  result.parse(`${open}${result.tagName}${close}${text}${open}/${result.tagName}${close}`, open, close);
  return result;
}

Node.prototype = {
  parse: function(content, open, close) {
    let index = -1;
    let state = -1;
    let tagName = '';
    let text = '';
    let quote = null;
    
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
          this.appendTEXT(text);
          return content.substring(index + (open + '/' + this.tagName + close).length, content.length);
        }
        
        if (content.indexOf('&gt;&gt;') == index || content.indexOf('>>') == index) {
          if (text.length) {
            this.appendTEXT(text);
            text = '';
          }
          content = this.parseReplyTag(content.substring(index, content.length).replace(/&gt;&gt;|>>/, ''));
          index = -1;
          continue;
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
            content = this.appendNode().parse(content.substring(index, content.length), open, close);
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
          this.parseTagName(tagName);
          
          if (content[index] == ' ') {
            content = this.parseAttributes(content.substring(index + 1, content.length), close);
            index = -1;
          }
          
          state = 1;
        } else {
          tagName += content[index];
        }
      }
      
      if (state == -1 && content[index] == open) {
        state = 0;
      }
    }
    
    this.appendTEXT(text);
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
    let index = -1;
    let quote = null;
    let par = '';
    
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
    
    if (par.length) this.equalsPar = par;
    return content.substring(index, content.length);
  },
  parseAtTag: function(content) {
    let atTag = content.split(/[\s\[\<]/)[0];
    this.appendNode('at').appendTEXT(atTag);
    return content.replace(atTag, '');
  },
  parseReplyTag: function(content) {
    let replyTag = content.split(/[^a-z0-9A-Z]/)[0];
    this.appendNode('reply').appendTEXT(replyTag);
    return content.replace(replyTag, '');
  },
  parseEmoticonAlias: function(content) {
    let emote = content.split(':');
    if (emote.length > 1) {
      emote = emote[1];
      if (emoticons.indexOf(emote) > -1) {
        this.appendNode('emote').appendTEXT(emote);
        return content.replace(`:${emote}:`, '');
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
          if (name.length) this.setAttribute(name, value);
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
            this.setAttribute(name, value);
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
  inner: function(type) {
    let ans = this.children.map(child => child.outer(type)).join('');
    if (type != 'html') return ans;
    return ans.trim().replace(/\n/g, '<br>');
  },
  outer: function(type) {
    if (type === 'text') return innerText();
    return getTagGenerator(this, type);
  },
  innerTEXT: function() {
    return this.inner('text');
  },
  innerHTML: function() {
    return this.inner('html');
  },
  innerBBC: function() {
    return this.inner('bbc');
  },
  outerHTML: function() {
    return this.outer('html');
  },
  outerBBC: function() {
    return this.outer('bbc');
  },
  depth: function() {
    if (!this.parent) return 0;
    return this.parent.depth() + 1;
  },
  even: function() {
    return !(this.depth() % 2);
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
  let result = null;
  if (tag.tagName.length) {
    result = tagGenerators[type].find(item => item.match.test(tag.tagName));
		if (result) return result.func(tag);
  }
  result = tagGenerators.default[type];
  return result ? result(tag) : '';
}

const tagGenerators = {
  default: {
    bbc: tag => tag.innerBBC(),
    html: tag => {
      if (tag.tagName.indexOf('yt') == 0 && !tag.tagName.replace('yt', '').match(/[^a-zA-z0-9\-_]/)) {
        return `<iframe allowfullscreen class="embed" src="https://www.youtube.com/embed/${tag.tagName.replace('yt', '')}"></iframe>${tag.innerHTML()}`;
      }
      if (tag.tagName.length && !tag.tagName.match(/[^0-9]/)) return `<iframe allowfullscreen class="embed" src="/embed/${tag.tagName}"></iframe>${tag.innerHTML()}`;
      return tag.innerHTML();
    }
  },
  bbc: [
    { match: /br/, func: tag => `\n${tag.innerBBC()}` },
    { match: /hr/, func: tag => `[hr]${tag.innerBBC()}` },
    { match: /b|u|s|sup|sub|spoiler/, func: tag => `[${tag.tagName}]${tag.innerBBC()}[/${tag.tagName}]` },
    { match: /blockquote/, func: tag => `[q]${tag.innerBBC()}[/q]` },
    { match: /at/, func: tag => `@${tag.innerTEXT()}`},
    { match: /reply/, func: tag => `>>${tag.innerTEXT()}` },
    { match: /img/, func: tag => `[img]${tag.attributes.src || ''}[img]${tag.innerBBC()}` },
    { match: /emote/, func: tag => `:${tag.innerTEXT()}:` },
    { match: /i/, func: tag => {
        if (tag.classes.indexOf('emote') != -1) {
          return `:${tag.attributes['data-emote']}:`;
        }
        if (tag.attributes.class && tag.attributes.class.indexOf('fa fa-fw fa-') == 0) {
          return `[icon]${tag.attributes.class.replace('fa fa-fw fa-', '').split(/[^a-zA-Z0-9]/)[0]}[/icon]`;
        }
        return `[${tag.tagName}]${tag.innerBBC()}[/${tag.tagName}]`;
      }
    },
    { match: /a/, func: tag => {
        if (!tag.attributes.href) return tag.innerBBC();
        if (tag.classes.indexOf('user-link') > -1) return `@${tag.innerTEXT()}`;
        if (tag.attributes['data-link']) {
          if (tag.attributes['data-link'] == '1') return tag.attributes['href'];
          if (tag.attributes['data-link'] == '2') return `>>${tag.attributes.href.replace('#comment_', '')}`;
        }
        return `[url=${tag.attributes.href}]${tag.innerBBC()}[/url]`;
      }
    },
    { match: /div/, func: tag => {
        if (tag.classes.indexOf('spoiler') > -1) {
          return '[spoiler]' + tag.innerBBC() + '[/spoiler]';
        }
        return tag.innerBBC();
      }
    },
    { match: /iframe/, func: tag => {
        if (tag.attributes.src && tag.attributes.class == 'embed') {
          if (tag.attributes.src.indexOf('youtube') > -1) {
            return `[yt${ytId(tag.attributes.src)}]${tag.innerBBC()}`;
          }
          return `[${tag.attributes.src.replace(/[^0-9]/g,'')}]${tag.innerBBC()}`;
        }
        return tag.innerBBC();
      }
		}
  ],
  html: [
    { match: /b|i|u|s|sup|sub|hr/, func: tag => `<${tag.tagName}>${tag.innerHTML()}</${tag.tagName}>` },
    { match: /icon/, func: tag => `<i class="fa fa-fw fa-${tag.innerTEXT().split(/[^a-zA-Z0-9]/)[0]}"></i>` },
    { match: /q/, func: tag => `<blockquote${tag.even() ? ' class="even"' : ''}>${tag.innerHTML()}</blockquote>` },
    { match: /url/, func: tag => `<a href="${tag.equalsPar || tag.innerTEXT()}">${tag.innerHTML()}</a>` },
    { match: /at/, func: tag => `<a class="user-link" data-id="0" href="/">${tag.innerTEXT()}</a>` },
    { match: /reply/, func: tag => `<a data-link="2" href="#comment_${tag.innerTEXT()}">${tag.innerTEXT()}</a>` },
    { match: /spoiler/, func: tag => `<div class="spoiler">${tag.innerHTML()}</div>` },
    { match: /img/, func: tag => `<img src="${tag.innerTEXT().replace(/['"]/g,'')}"></img>` },
    { match: /emote/, func: tag => `<i class="emote" data-emote="${tag.innerTEXT()}">:${tag.innerTEXT()}:</i>` }
  ]
};

export const BBCode = {
  fromHTML: html => Node.parse(html, '<', '>'),
  fromBBC: bbc => Node.parse(bbc, '[', ']')
};