import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';
import { BBCode } from '../utils/bbcode';

var active = null;
var emptyMessage = 'A description has not been written yet.';

var keyEvents = {
  66: 'b', 85: 'u', 73: 'i', 83: 's', 80: 'spoiler'
};

var specialActions = {
  tag: function(sender, textarea) {
    var tag = sender.dataset.tag;
    insertTags(textarea, '[' + tag + ']', '[/' + tag + ']');
  },
  emoticons: function(sender) {
    sender.classList.remove('edit-action');
    sender.querySelector('.pop-out').innerHTML = emoticons.map(function(e) {
      return '<li class="edit-action" data-action="emoticon" title=":' + e + ':"><span class="emote ' + e + '" title=":' + e + ':" alt=":' + e + ':"></span></li>';
    }).join('');
  },
  emoticon: function(sender, textarea) {
    insertTags(textarea, sender.title, '');
  }
};

function handleSpecialKeys(key, callback) {
  var k = keyEvents[key];
  if (k) return callback(k);
  if (key == 13) deactivate(active);
}

function initEditable(holder, content, short) {
  var textarea = holder.querySelector('.input');
  if (!textarea) {
    textarea = document.createElement(short ? 'input' : 'textarea');
    textarea.className = 'input js-auto-resize';
    content.insertAdjacentElement('afterend', textarea);
  }
  textarea.addEventListener('change', function() {
    holder.classList.add('dirty');
  });
  textarea.addEventListener('keydown', function(ev) {
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
  updatePreview(textarea);
}

function toggleEdit(editing, holder, content, textarea, short) {
  const text = content.textContent.toLowerCase().trim();
  if (!editing) {
    const hovercard = content.querySelector('.hovercard');
    if (hovercard) hovercard.parentNode.removeChild(hovercard);
    textarea.value = BBCode.fromHTML(content.innerHTML).outerBBC();
    holder.classList.add('editing');
    textarea.dispatchEvent(new Event('keyup'));
  } else {
    if (!text || !text.length || text === emptyMessage.toLowerCase()) {
      content.textContent = emptyMessage;
    }
    if (short) {
      content.textContent = BBCode.fromHTML(textarea.value).outerBBC();
    } else {
      content.innerHTML = BBCode.fromBBC(textarea.value).outerHTML();
    }
    holder.classList.remove('editing');
    updatePreview(textarea);
  }
  return !editing;
}

function save(action, id, field, holder) {
  if (holder.classList.contains('dirty')) {
    holder.classList.add('saving');
    ajax.patch(action + ',' + id, {
      field: field,
      value: BBCode.fromBBC(holder.querySelector('.input').value).outerBBC()
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

export function setupEditable(sender) {
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

function updatePreview(sender) {
  const preview = sender.parentNode.querySelector('.comment-content.preview');
  if (preview) preview.innerHTML = BBCode.fromBBC(sender.value).outerHTML();
}

jSlim.on(document, 'change', 'textarea.comment-content', function() {
  updatePreview(this);
});

jSlim.on(document, 'keydown', 'textarea.comment-content', function(ev) {
  if (ev.ctrlKey) {
    handleSpecialKeys(ev.keyCode, tag => {
      insertTags(this, '[' + tag + ']', '[/' + tag + ']');
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

jSlim.ready(function() {
  jSlim.all('.editable', setupEditable);
  jSlim.all('.post-box textarea.comment-content, .post-box input.comment-content', updatePreview);
});
