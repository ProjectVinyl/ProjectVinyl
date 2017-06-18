import { ajax } from './ajax.js';

var active = null;
var emptyMessage = 'A description has not been written yet.';

var keyEvents = {
  66: 'b', 85: 'u', 73: 'i', 83: 's', 80: 'spoiler'
};

var specialActions = {
  tag: function(sender, textarea) {
    var tag = sender.attr('data-tag');
    insertTags(textarea, '[' + tag + ']', '[/' + tag + ']');
    $(textarea).trigger('change');
  },
  emoticons: function(sender) {
    sender.removeClass('edit-action');
    sender.find('.pop-out').html(emoticons.map(function(e) {
      return '<li class="edit-action" data-action="emoticon" title=":' + e + ':"><img title=":' + e + ':" alt=":' + e + ':" src="/emoticons/' + e + '.png"></li>';
    }).join(''));
  },
  emoticon: function(sender, textarea) {
    insertTags(textarea, sender.attr('title'), '');
    $(textarea).trigger('change');
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
  var textarea = holder.find('.input');
  if (!textarea.length) {
    if (short) {
      textarea = $('<input class="input" />');
      textarea.css('height', content.innerHeight() + 20);
      textarea.css('width', content.innerWidth() + 20);
      content.after(textarea);
    } else {
      textarea = $('<textarea class="input" />');
      textarea.css('height', content.innerHeight() + 20);
      content.after(textarea);
    }
  }
  if (!short) {
    textarea.on('keydown keyup', function() {
      var height = textarea.height();
      textarea.css('height', 0);
      textarea.css('margin-bottom', height);
      textarea.css('height', textarea[0].scrollHeight + 20);
      textarea.css('margin-bottom', '');
    });
  } else {
    textarea.on('keydown keyup', function() {
      var width = textarea.width();
      textarea.css('width', 0);
      textarea.css('margin-left', width);
      textarea.css('width', textarea[0].scrollWidth + 20);
      textarea.css('margin-left', '');
    });
  }
  textarea.on('change', function() {
    holder.addClass('dirty');
  });
  textarea.on('keydown', function(ev) {
    if (ev.ctrlKey) {
      handleSpecialKeys(ev.keyCode, function(tag) {
        insertTags(textarea[0], '[' + tag + ']', '[/' + tag + ']');
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
  var text = content.text().toLowerCase().trim();
  if (!editing) {
    content.find('.hovercard').remove();
    textarea.val(poor(content.html()));
    holder.addClass('editing');
  } else {
    if (!text || !text.length || text == emptyMessage.toLowerCase()) {
      content.text(emptyMessage);
    }
    if (short) {
      content.text(poor(textarea.val()));
    } else {
      content.html(rich(textarea.val()));
    }
    holder.removeClass('editing');
    holder.trigger('change');
  }
  return !editing;
}

function save(action, id, field, holder) {
  if (holder.hasClass('dirty')) {
    holder.addClass('saving');
    ajax.post(action, function() {
      holder.removeClass('saving');
      holder.removeClass('dirty');
    }, true, {
      id: id, field: field, value: poor(holder.find('.input').val())
    });
  }
}

function deactivate(button) {
  active = null;
  button.trigger('click');
}

function setupEditable(sender) {
  var editing = false;
  var id = sender.dataset.id;
  var member = sender.dataset.member;
  var target = sender.dataset.target;
  var short = sender.classList.contains('short');
  var me = $(sender);
  var content = me.children('.content');
  var button = me.children('.edit');
  var textarea = initEditable(me, content, short);
  
  button.on('click', function() {
    if (active && active != button) deactivate(active);
    editing = toggleEdit(editing, me, content, textarea, short);
    active = editing ? button : null;
    if (!editing && target) {
      save('update/' + target, id, member, me);
    }
  });
  me.on('click', function(ev) {
    ev.stopPropagation();
  });
}

$doc.on('click', function() {
  if (active && !active.closest('.editable').is(':hover')) deactivate(active);
});

$doc.on('change', 'textarea.comment-content', function() {
  var preview = $(this).parent().find('.comment-content.preview');
  if (preview.length) {
    preview.html(rich($(this).val()));
  }
});

$doc.on('keydown', 'textarea.comment-content', function(ev) {
  var self = this;
  if (ev.ctrlKey) {
    handleSpecialKeys(ev.keyCode, function(tag) {
      insertTags(self, '[' + tag + ']', '[/' + tag + ']');
      $(self).trigger('change');
      ev.preventDefault();
    });
  }
});

$doc.on('mouseup', '.edit-action', function() {
  var sender = $(this);
  var textarea = sender.parents('.content.editing').find('textarea, input.comment-content')[0];
  var type = specialActions[sender.attr('data-action')];
  if (type) type(sender, textarea);
});

$doc.on('dragstart', '#emoticons img[title]', function(event) {
  var data = event.originalEvent.dataTransfer.getData('Text/plain');
  if (data && data.trim().indexOf('[') == 0) {
    data = data.split('\n');
    for (var i = data.length; i--;) {
      data[i] = data[i].trim().replace(/\[/g, '').replace(/\]/g, '');
    }
    event.originalEvent.dataTransfer.setData('Text/plain', data.join(''));
  } else {
    event.originalEvent.dataTransfer.setData('Text/plain', $(this).attr('title'));
  }
});

$doc.on('keydown', '#emoticons', function() {
  $(this).select();
});

$(function() {
  $('.editable').each(function() {
    setupEditable(this);
  });
  $('.post-box textarea.comment-content, .post-box input.comment-content').trigger('change');
});

const BBC = Object.freeze({
  rich: rich,
  poor: poor,
  init: setupEditable
});

export { BBC };
