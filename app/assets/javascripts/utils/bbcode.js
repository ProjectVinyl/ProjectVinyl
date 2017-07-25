import { ajax } from './ajax';
import { jSlim } from './jslim';

var active = null;
var emptyMessage = 'A description has not been written yet.';

var keyEvents = {
  66: 'b', 85: 'u', 73: 'i', 83: 's', 80: 'spoiler'
};

var specialActions = {
  tag: function(sender, textarea) {
    var tag = sender.dataset.tag;
    insertTags(textarea, '[' + tag + ']', '[/' + tag + ']');
    textarea.dispatchEvent(new Event('change'));
  },
  emoticons: function(sender) {
    sender.classList.remove('edit-action');
    sender.querySelector('.pop-out').innerHTML = emoticons.map(function(e) {
      return '<li class="edit-action" data-action="emoticon" title=":' + e + ':"><span class="emote ' + e + '" title=":' + e + ':" alt=":' + e + ':"></span></li>';
    }).join('');
  },
  emoticon: function(sender, textarea) {
    insertTags(textarea, sender.title, '');
    textarea.dispatchEvent(new Event('change'));
  }
};

function handleSpecialKeys(key, callback) {
  var k = keyEvents[key];
  if (k) return callback(k);
  if (key == 13) deactivate(active);
}

function rich(text) {
  text = text.replace(/</g, '&lt;').replace(/>/g, '&gt;');
  text = text.replace(/@([^\s\[<]+)/, '<a class="user-link" data-id="0" href="/">$1</a>');
  text = text.replace(/\[icon\]([^\[]+)\[\/icon\]/g, '<i class="fa fa-fw fa-$1"></i>');
  text = text.replace(/\n/g, '<br>').replace(/\[([/]?([buis]|sup|sub|hr))\]/g, '<$1>').replace(/\[([/]?)q\]/g, '<$1blockquote>');
  text = text.replace(/\[url=([^\]]+)]/g, '<a href="$1">').replace(/\[\/url]/g, '</a>');
  text = text.replace(/\[spoiler\]/g, '<div class="spoiler">').replace(/\[\/spoiler\]/g, '</div>');
  text = text.replace(/\[img\]([^\[]+)\[\/img\]/g, '<span class="img"><img src="$1"></span>');
  text = text.replace(/([^">]|[\s]|<[/]?br>|^)(http[s]?:\/\/[^\s\n<]+)([^"<]|[\s\n]|<br>|$)/g, '$1<a data-link="1" href="$2">$2</a>$3');
  text = text.replace(/([^">]|[\s]|<[/]?br>|^)(>>|&gt;&gt;)([0-9a-z]+)([^"<]|[\s\n]|<br>|$)/g, '$1<a data-link="2" href="#comment_$3">$2$3</a>$4');
  
  var i = emoticons.length;
  while (i--) {
    text = text.replace(new RegExp(':' + emoticons[i] + ':', 'g'), '<img class="emoticon" src="/emoticons/' + emoticons[i] + '.png">');
  }
  
  text = text.replace(/\[([0-9]+)\]/, '<iframe class="embed" src="/embed/$1" allowfullscreen></iframe>');
  text = text.replace(/\[yt([^\]]+)\]/, '<iframe class="embed" src="https://www.youtube.com/embed/$1" allowfullscreen></iframe>');
  return text;
}

function poor(text) {
  text = text.replace(/<i class="fa fa-fw fa-([^"]+)"><\/i>/g, '[icon]$1[/icon]');
  text = text.replace(/<a class="user-link" data-id="[0-9]+" href="[^"]+">([^<]+)<\/a>/g, '@$1');
  text = text.replace(/<br>/g, '\n').replace(/<([/]?([buis]|sup|sub|hr))>/g, '[$1]').replace(/<([/]?)blockquote>/g, '[$1q]');
  text = text.replace(/<a data-link="1" href="([^"]+)">[^<]*<\/a>/g, '$1');
  text = text.replace(/<a data-link="2" href="[^"]+">([^<]*)<\/a>/g, '$1');
  text = text.replace(/<\/img>/g, '').replace(/<span class="img"><img src="([^"]+)"><\/span>/g, '[img]$1[/img]');
  text = text.replace(/<a href="([^"]+)">/g, '[url=$1]').replace(/<\/a>/g, '[/url]');
  text = text.replace(/<div class="spoiler">/g, '[spoiler]').replace(/<\/div>/g, '[/spoiler]');
  
  var i = emoticons.length;
  while (i--) {
    text = text.replace(new RegExp('<img class="emoticon" src="/emoticons/' + emoticons[i] + '.png">', 'g'), ':' + emoticons[i] + ':');
  }
  
  text = text.replace(/<iframe class="embed" src="\/embed\/([0-9+])" allowfullscreen><\/iframe>/, '[$1]');
  text = text.replace(/<iframe class="embed" src="https:\/\/www.youtube.come\/embed\/([^&"]+)[^"]*" allowfullscreen><\/iframe>/, '[yt$1]');
  return text;
}

function initEditable(holder, content, short) {
  var textarea = holder.querySelector('.input');
  if (!textarea) {
    if (short) {
      textarea = document.createElement('input');
      textarea.className = 'input js-auto-resize';
      textarea.style.height = (content.clientHeight + 20) + 'px';
      textarea.style.width = (content.clientWidth + 20) + 'px';
      content.insertAdjacentElement('afterend', textarea);
    } else {
      textarea = document.createElement('textarea');
      textarea.className = 'input';
      textarea.style.height = (content.clientHeight + 20) + 'px';
      content.insertAdjacentElement('afterend', textarea);
    }
  }
  if (!short) {
    function changeHeight() {
      const height = getComputedStyle(textarea).height;
      textarea.style.height = 0;
      textarea.style.marginBottom = height;
      textarea.style.height = (textarea.scrollHeight + 20) + 'px';
      textarea.style.marginBottom = '';
    }
    textarea.addEventListener('keydown', changeHeight);
    textarea.addEventListener('keyup', changeHeight);
  }
  textarea.addEventListener('change', () => holder.classList.add('dirty'));
  textarea.addEventListener('keydown', ev => {
    if (ev.ctrlKey) {
      handleSpecialKeys(ev.keyCode, function(tag) {
        insertTags(textarea, '[' + tag + ']', '[/' + tag + ']');
        ev.preventDefault();
      });
    }
  });
  return textarea;
}

function insertTags(textarea, open, close) {
  var start = textarea.selectionStart;
  if (!start && start != 0) return;
  var end = textarea.selectionEnd;
  var before = textarea.value.substring(0, start);
  var after = textarea.value.substring(end, textarea.value.length);
  var selected = end - start > 0 ? textarea.value.substring(start, end) : '';
  
  if (selected.indexOf(open) > -1 || (selected.indexOf(close) > -1 && close)) {
    selected = selected.replace(open, '').replace(close, '');
  } else {
    selected = open + selected + close;
  }
  
  textarea.value = before + selected + after;
  textarea.selectionStart = start;
  textarea.selectionEnd = start + selected.length;
  textarea.focus();
}

function toggleEdit(editing, holder, content, textarea, short) {
  const text = content.textContent.toLowerCase().trim();
  if (!editing) {
    const hovercard = content.querySelector('.hovercard');
    if (hovercard) hovercard.parentNode.removeChild(hovercard);
    textarea.value = poor(content.innerHTML);
    holder.classList.add('editing');
  } else {
    if (!text || !text.length || text === emptyMessage.toLowerCase()) {
      content.textContent = emptyMessage;
    }
    if (short) {
      content.textContent = poor(textarea.value);
    } else {
      content.innerHTML = rich(textarea.value);
    }
    holder.classList.remove('editing');
    holder.dispatchEvent(new Event('change'));
  }
  return !editing;
}

function save(action, id, field, holder) {
  if (holder.classList.contains('dirty')) {
    holder.classList.add('saving');
    ajax.post(action, {
      id: id,
      field: field,
      value: poor(holder.querySelector('.input').value)
    }).text(function() {
      holder.classList.remove('saving');
      holder.classList.remove('dirty');
    });
  }
}

function deactivate(button) {
  active = null;
  button.click();
}

function setupEditable(sender) {
  var editing = false;
  var id = sender.dataset.id;
  var member = sender.dataset.member;
  var target = sender.dataset.target;
  var short = sender.classList.contains('short');
  var content = sender.querySelector('.content');
  var button = sender.querySelector('.edit');
  var textarea = initEditable(sender, content, short);
  
  button.addEventListener('click', function() {
    if (active && active != button) deactivate(active);
    editing = toggleEdit(editing, sender, content, textarea, short);
    active = editing ? button : null;
    if (!editing && target) {
      save('update/' + target, id, member, sender);
    }
  });
  sender.addEventListener('click', function(ev) {
    ev.stopPropagation();
  });
}

document.addEventListener('click', () => {
  if (active && !active.closest('.editable').matches(':hover')) deactivate(active);
});

jSlim.on(document, 'change', 'textarea.comment-content', function() {
  const preview = this.parentNode.querySelector('.comment-content.preview');
  if (preview) preview.innerHTML = rich(this.value);
});

jSlim.on(document, 'keydown', 'textarea.comment-content', function(ev) {
  if (ev.ctrlKey) {
    handleSpecialKeys(ev.keyCode, tag => {
      insertTags(this, '[' + tag + ']', '[/' + tag + ']');
      this.dispatchEvent(new Event('change'));
      ev.preventDefault();
    });
  }
});

jSlim.on(document, 'mouseup', '.edit-action', function() {
  const textarea = this.closest('.content.editing').querySelector('textarea, input.comment-content');
  const type = specialActions[this.dataset.action];
  if (type) type(this, textarea);
});

jSlim.on(document, 'dragstart', '#emoticons .emote[title]', function(event) {
  let data = event.dataTransfer.getData('Text/plain');
  if (data && data.trim().indexOf('[') == 0) {
    data = data.split('\n');
    for (var i = data.length; i--;) {
      data[i] = data[i].trim().replace(/\[/g, '').replace(/\]/g, '');
    }
    event.dataTransfer.setData('Text/plain', data.join(''));
  } else {
    event.dataTransfer.setData('Text/plain', this.title);
  }
});

jSlim.ready(() => {
  jSlim.all('.editable', e => setupEditable(e));
  jSlim.all('.post-box textarea.comment-content, .post-box input.comment-content', c => {
    c.dispatchEvent(new Event('change'));
  });
});

const BBC = Object.freeze({
  rich: rich,
  poor: poor,
  init: setupEditable
});

export { BBC };
