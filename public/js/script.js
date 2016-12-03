if (navigator.userAgent.indexOf("OPR") !== -1) {
  $('html').addClass('opera');
}
var window_focused = false;
$(window).on('focus', function() {
  window_focused = true;
});
$(window).on('blur', function () {
  window_focused = false;
});
var worker;
$(window).ready(function () {
	function scroller() {
		var top = window.scrollY;
    var width = window.innerWidth;
		if (top <= 200) banner.css('background-position', 'top calc(50% + ' + (top*0.5) + 'px) ' + (width > 1300 ? 'left' : 'center') + ', top calc(50% + ' + (top*0.5) + 'px) right');
	}
	var banner = $('#banner');
	if (banner.length) {
		if (window.requestAnimationFrame) {
			function animator() {
				scroller();
				window.requestAnimationFrame(animator);
			}
			animator();
		} else {
			console.log('RequestAnimationFrame not supported. Using scroll instead');
			$(window).on('scroll', scroller);
		}
	}
  
  if (window['current_user'] && window.SharedWorker && (window['force_notifications'] || !!localStorage['give_me_notifications'])) {
    var doc_title = $('#document_title');
    var title = doc_title.text();
    worker = new SharedWorker('/js/notifications.js?1');
    worker.port.addEventListener('message', function(e) {
      if (e.data.command == 'feeds') {
        if (e.data.count > 0) {
          $('.notices-bell.feeds').html('<i class="fa fa-globe" /><span>' + e.data.count + '</span>');
        } else {
          $('.notices-bell.feeds').html('<i class="fa fa-globe" />');
        }
      } else if (e.data.command == 'notices') {
        $('.notices-bell.notices span:not(.invert)').remove();
        if (e.data.count > 0) {
          $('.notices-bell.notices i').after('<span>' + e.data.count + '</span>');
        }
      } else if (e.data.command == 'mail') {
        if (e.data.count > 0) {
          $('.notices-bell.notices').append('<span class="invert">' + e.data.count + '</span>');
        } else {
          $('.notices-bell.notices span.invert').remove();
        }
      } else if (e.data.command == 'chat') {
        var chat = $('#chat');
        chat.html(e.data.content);
        chat = chat.parent();
        chat.scrollTop(chat.height());
      }
      if (e.data.command == 'notices' || e.data.command == 'feeds' || e.data.command == 'mail') {
        if (!window_focused && e.data.count) {
          if (title.indexOf('*') !== 0) {
            title = '* ' + title;
            doc_title.text(title);
          }
        } else {
          if (title.indexOf('*') == 0) {
            title = title.replace('* ', '');
            doc_title.text(title);
          }
        }
      }
    });
    $(window).on('focus', function() {
      if (title.indexOf('*') == 0) {
        title = title.replace('* ', '');
        doc_title.text(title);
      }
    });
    worker.port.start();
    worker.port.postMessage({
      command: 'connect',
      notices: $('.notices-bell.notices span').length ? parseInt($('.notices-bell.notices span').text()) : 0,
      feeds: $('.notices-bell.feeds span').length ? parseInt($('.notices-bell.feeds span').text()) : 0
    });
    window.onbeforeunload = function() {
      worker.port.postMessage({command: 'disconnect'});
      return null;
    };
  }
});
var ajax = (function() {
  var token = $('meta[name=csrf-token]').attr('content');
  function request(method, resource, callback, data, direct) {
    $.ajax({
      type: method,
      datatype: 'text',
      url: resource,
      success: direct ? callback : function(xml, type, ev) {
        callback(ev.status == 204 ? {} : JSON.parse(ev.responseText), ev.status);
      },
      error: function(d) {
        console.log(method + ' ' + resource + '\n\n' + d.responseText);
      },
      data: data
    });
  }
  function result(resource, callback, direct) {
    request('GET', '/ajax/' + resource, callback, {}, direct);
  }
  function auth(data) {
    if (!data) data = {};
    data.authenticity_token = token;
    return data;
  }
  result.form = function(form, e, callbacks) {
    if (e) e.preventDefault();
    var message = form.find('.progressor .message');
    var fill = form.find('.progressor .fill');
    var uploadedBytes = 0;
    var totalBytes = 0;
    var secondsRemaining = 0;
    var timeStarted = new Date();
    var timer;
    callbacks = callbacks || {};
    $.ajax({
      type: form.attr('method'),
      url: form.attr('action') + '/async',
      enctype: 'multipart/form-data',
      data: new FormData(form[0]),
      xhr: function() {
        var xhr = $.ajaxSettings.xhr();
        if (xhr.upload) {
          xhr.upload.addEventListener('progress', function(e) {
            uploadedBytes = e.loaded;
            totalBytes = e.total
            if (e.lengthComputable) {
              if (!message.hasClass('plain')) message.addClass('bobber');
              var percentage = Math.min((e.loaded / e.total) * 100, 100);
              if (callbacks.progress) {
                callbacks.progress.apply(form, [e, message, fill, percentage]);
              } else {
                if (percentage >= 100) {
                  form.addClass('waiting');
                  message.text('Waiting for server...');
                } else {
                  var measure = 's';
                  var time = secondsRemaining;
                  if (time >= 60) {
                    time /= 60;
                    measure = 'm';
                  }
                  if (time >= 60) {
                    time /= 60;
                    measure = 'h';
                  }
                  if (time >= 24) {
                    time /= 24;
                    measure = 'd';
                  }
                  message.text((Math.floor(time*100)/100) + measure + ' remaining (' + Math.floor(percentage) + '% )');
                }
                fill.css('width', percentage + '%');
                message.css({
                  'left': percentage + '%'
                });
              }
              message.css({
                'margin-left': -message.outerWidth()/2
              });
            }
          }, false);
        }
        return xhr;
      },
      beforeSend: function() {
        timer = setInterval(function() {
          var timeElapsed = (new Date()) - timeStarted;
          var uploadSpeed = uploadedBytes / (timeElapsed / 1000);
          secondsRemaining = (totalBytes - uploadedBytes) / uploadSpeed;
        }, 1000);
        form.addClass('uploading');
      },
      success: callbacks.success || function (data) {
        if (timer) clearInterval(timer);
        if (data.ref) {
          document.location.href = data.ref;
        }
      },
      error: function(e, err, msg) {
        if (timer) clearInterval(timer);
        form.removeClass('waiting').addClass('error');
        if (callbacks.error) return callbacks.error(message, msg, e.responseText);
        message.text(e.responseText);
      },
      cache: false,
      contentType: false,
      processData: false
    });
  };
  result.post = function(resource, callback, direct, data) {
    request('POST', '/ajax/' + resource, callback, auth(data), direct);
  };
  result.delete = function(resource, callback, direct) {
    request('DELETE', resource, callback, {
      authenticity_token: token
    }, direct);
  };
  result.get = function(resource, callback, data, direct) {
    request('GET', '/ajax/' + resource, callback, data, direct);
  };
  return result;
})();
var scrollTo = (function() {
  function scrollIntoView(me, container, viewport) {
    if (!me.length) return;
    var offset = me.offset();
    var scrollpos = container.offset();
    container.animate({
      scrollTop: offset.top - scrollpos.top - viewport.height()/2 + me.height()/2,
      scrollLeft: offset.left - scrollpos.left - viewport.width()/2 + me.width()/2
    });
    return me;
  };
  return function(el, container, viewport) {
    return scrollIntoView($(el), $(container || 'html, body'), $(viewport || window));
  };
})();
var resizeFont = (function() {
  function sizeFont(el, targetWidth) {
    var div = $('<div style="position:fixed;top:0;left:0;white-space:nowrap;background:#fff" />');
    div.css('font-family', el.css('font-family'));
    div.css('font-weight', el.css('font-weight'));
    div.css('font-size-adjust', el.css('font-size-adjust'));
    div.text(el.text());
    el.css('font-size', '');
    var size = parseFloat(el.css('font-size'));
    div.css('font-size', size);
    $('body').append(div);
    var currentWidth = div.width();
    var factor = -1;
    while (currentWidth > targetWidth) {
      factor = targetWidth/currentWidth;
      size *= factor;
      div.css('font-size', size);
      currentWidth = div.width();
    }
    if (size < 5) size = 5;
    el.css('font-size', size);
    div.remove();
  }
  function resizeFont(el) {
    sizeFont(el, el.closest('.resize-holder').width());
  }
  function fixFonts() {
    $('h1.resize-target').each(function() {
      resizeFont($(this));
    });
  }
  $(window).on('resize', fixFonts);
  fixFonts();
  return resizeFont;
})();
var BBC = (function() {
  var active = null;
  var emptyMessage = 'A description has not been written yet.';
  function rich(text) {
    text = text.replace(/</g,'&lt;').replace(/>/g,'&gt;');
    text = text.replace(/@([^\s\[\<]+)/, '<a class="user-link" data-id="0" href="/">$1</a>');
    text = text.replace(/\[icon\]([^\[]+)\[\/icon\]/g, '<i class="fa fa-fw fa-$1"></i>');
    text = text.replace(/\n/g, '<br>').replace(/\[([\/]?([buis]|sup|sub|hr))\]/g, '<$1>').replace(/\[([\/]?)q\]/g, '<$1blockquote>');
    text = text.replace(/\[url=([^\]]+)]/g, '<a href="$1">').replace(/\[\/url]/g, '</a>');
    text = text.replace(/\[spoiler\]/g, '<div class="spoiler">').replace(/\[\/spoiler\]/g, '</div>');
    text = text.replace(/\[img\]([^\[]+)\[\/img\]/g, '<span class="img"><img src="$1"></span>');
    text = text.replace(/([^">]|[\s]|<[\/]?br>|^)(http[s]?:\/\/[^\s\n<]+)([^"<]|[\s\n]|<br>|$)/g, '$1<a data-link="1" href="$2">$2</a>$3');
    var i = emoticons.length;
    while (i--) {
      text = text.replace(new RegExp(':' + emoticons[i] + ':', 'g'), '<img class="emoticon" src="/emoticons/' + emoticons[i] + '.png">');
    }
		text = text.replace(/\[([0-9]+)\]/, '<iframe class="embed" src="/embed/$1" allowfullscreen></iframe>');
		text = text.replace(/\[yt([^\]]+)\]/, '<iframe class="embed" src="https://www.youtube.com/embed?v=$1" allowfullscreen></iframe>');
    return text;
  }
  function poor(text) {
    text = text.replace(/<i class="fa fa-fw fa-([^"]+)"><\/i>/g, '[icon]$1[/icon]');
    text = text.replace(/<a class="user-link" data-id="[0-9]+" href="[^"]+">([^<]+)<\/a>/g, '@$1');
    text = text.replace(/<br>/g, '\n').replace(/<([\/]?([buis]|sup|sub|hr))>/g, '[$1]').replace(/<([\/]?)blockquote>/g, '[$1q]');
    text = text.replace(/<a data-link="1" href="([^"]+)">[^<]*<\/a>/g, '$1');
    text = text.replace(/<\/img>/g, '').replace(/<span class="img"><img src="([^"]+)"><\/span>/g, '[img]$1[/img]');
    text = text.replace(/<a href="([^"]+)">/g, '[url=$1]').replace(/<\/a>/g, '[/url]');
    text = text.replace(/\<div class="spoiler">/g, '[spoiler]').replace(/<\/div>/g, '[/spoiler]');
    var i = emoticons.length;
    while (i--) {
      text = text.replace(new RegExp('<img class="emoticon" src="/emoticons/' + emoticons[i] + '.png">', 'g'), ':' + emoticons[i] + ':');
    }
		text = text.replace(/<iframe class="embed" src="\/embed\/([0-9+])" allowfullscreen><\/iframe>/, '[$1]');
    text = text.replace(/<iframe class="embed" src="https:\/\/www.youtube.come\/embed?v=([^&"]+)[^"]*" allowfullscreen><\/iframe>/, '[yt$1]');
    return text;
  }
  function initEditable(holder, content, short) {
    var textarea = holder.find('.input');
    var lastHeight = 0;
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
      textarea.on('keydown keyup', function(ev) {
        var height = textarea.height();
        textarea.css('height', 0);
        textarea.css('margin-bottom', height);
        textarea.css('height', textarea[0].scrollHeight + 20);
        textarea.css('margin-bottom', '');
      });
    } else {
      textarea.on('keydown keyup', function(ev) {
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
  var key_events = {
    66: 'b',85: 'u',73: 'i',83: 's',80: 'spoiler'
  };
  function handleSpecialKeys(key, callback) {
    var k;
    if (k = key_events[key]) {
      callback(k);
    } else if (key == 13) {
      deactivate(active);
    }
  }
  function insertTags(textarea, open, close) {
    var start = textarea.selectionStart;
    if (start || start == 0) {
      var end = textarea.selectionEnd;
      var before = textarea.value.substring(0, start);
      var after = textarea.value.substring(end, textarea.value.length);
      var selected = end - start > 0 ? textarea.value.substring(start, end) : '';
      if (selected.indexOf(open) != -1 || (selected.indexOf(close) != -1 && close)) {
        selected = selected.replace(open, '').replace(close, '');
      } else {
        selected = open + selected + close;
      }
      textarea.value = before + selected + after;
      textarea.selectionStart = start;
      textarea.selectionEnd = start + selected.length;
      textarea.focus();
    }
  }
  function toggleEdit(editing, holder, content, textarea, short) {
    var text = content.text().toLowerCase().trim();
    var textarea = holder.find('.input');
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
  $('.editable').each(function() {
    var editing = false;
    var me = $(this);
    var id = me.attr('data-id');
    var member = me.attr('data-member');
    var target = me.attr('data-target');
    var short = me.hasClass('short');
    
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
  });
  $(document).on('click', function() {
    if (active && !active.closest('.editable').is(':hover')) deactivate(active);
  });
  $(document).on('change', 'textarea.comment-content', function() {
    var preview = $(this).parent().find('.comment-content.preview');
    if (preview.length) {
      preview.html(rich($(this).val()));
    }
  });
  $(document).on('keydown', 'textarea.comment-content', function(ev) {
    if (ev.ctrlKey) {
      var me = this;
      handleSpecialKeys(ev.keyCode, function(tag) {
        insertTags(me, '[' + tag + ']', '[/' + tag + ']');
        $(me).trigger('change');
        ev.preventDefault();
      });
    }
  });
  $(document).on('mouseup', '.edit-action', function() {
    var me = $(this);
    var type = me.attr('data-action');
    var textarea = me.parents('.content.editing').find('textarea, input.comment-content')[0];
    if (type == 'tag') {
      var tag = me.attr('data-tag');
      insertTags(textarea, '[' + tag + ']', '[/' + tag + ']');
      $(textarea).trigger('change');
    } else if (type == 'emoticons') {
      me.removeClass('edit-action');
      me.find('.pop-out').html(emoticons.map(function(e) {
        return '<li class="edit-action" data-action="emoticon" title=":' + e + ':"><img title=":' + e + ':" alt=":' + e + ':" src="/emoticons/' + e + '.png"></li>';
      }).join(''));
    } else if (type == 'emoticon') {
      insertTags(textarea, me.attr('title'), '');
      $(textarea).trigger('change');
    }
  });
  $(document).on('dragstart', '#emoticons img[title]', function(event) {
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
  })
  $(document).on('keydown', '#emoticons', function() {
    $(this).select();
  });
  $('.post-box textarea.comment-content, .post-box input.comment-content').trigger('change');
  return {
    rich: rich, poor: poor
  }
})();
var initFileSelect = (function() {
  function validateTypes(type, file) {
    if (type == 'image') {
      return !!file.type.match(/image\//);
    } else if (type == 'a/v') {
      return !!file.type.match(/(audio|video)\//);
    }
    return false;
  }
  function initFileSelect(me) {
    var type = me.attr('data-type');
    var allowMulti = me.attr('allow-multi') || false;
    var input = me.find('input').first();
    input.on('click', function(e) {
      e.stopPropagation();
    });
    me.on('dragover dragenter', function() {
      me.addClass('drag');
    });
    me.on('dragleave drop', function() {
      me.removeClass('drag');
    })
    if (me.hasClass('image-selector') && window.FileReader) {
      input.on('change', function() {
        if (!validateTypes(type, input[0].files[0])) {
          error('An encorrect file type was selected. Please try again.');
          return;
        }
        var preview = me.find('.preview');
        var img = preview[0];
        if (img.src) {
          URL.revokeObjectURL(img.src);
        }
        img.src = URL.createObjectURL(input[0].files[0]);
        preview.css('background-image', 'url(' + img.src + ')');
        me.trigger('accept');
      });
    } else {
      input.on('change', function() {
        if (!validateTypes(type, input[0].files[0])) {
          error('An encorrect file type was selected. Please try again.');
        } else {
          var title = input[0].files[0].name.split('.');
          title = title.splice(0, title.length - 1).join('.');
          me.trigger('accept', {title: title, mime: input[0].files[0].type, data: input[0].files[0]});
        }
      });
    }
    return me;
  }
  $('.file-select').each(function() {
    initFileSelect($(this));
  });
  return initFileSelect;
})();
(function() {
  var KEY_ENTER = 13, KEY_COMMA = 188, KEY_BACKSPACE = 8;
  $('.tag-editor').each(function() {
    var history = [];
    var me = $(this);
    me.find('.values').remove();
    me[0].getActiveTagsArray = function() {
      return tags;
    };
    var value = me.find('.value textarea');
    var list = me.find('ul.tags');
    var tags = value.val().replace(/,,|^,|,$/g,'');
    var searchResults = me.find('.search-results');
    var target = value.attr('data-target');
    var id = value.attr('data-id');
    
    if (tags.length) {
      tags = tags.split(',');
    } else {
      tags = [];
    }
    if (list.children().length == 0 && tags.length > 0) {
      for (var i = 0; i < tags.length; i++) {
        createTagItem(tags[i]);
      }
    }
    
    value.val(tags.join(','));
    list.find('.remove').on('click', function() {
      removeTag($(this).parent(), $(this).attr('data-name'));
    });
    function appendTag(name) {
      name = name.trim().toLowerCase().replace(/[^ a-z0-9\/&\-:]/g, '');
      if (name.length && name.indexOf('uploader:') != 0 && name.indexOf('title:') != 0) {
        if (tags.indexOf(name) == -1) {
          pickupTag(name);
          history.unshift({type: 1, tag: name});
        }
      }
    }
    function pickupTag(name) {
      tags.push(name);
      value.val(tags.join(','));
      createTagItem(name);
    }
    function namespace(name) {
      if (name.indexOf(':') != -1) {
        return name.split(':')[0];
      }
      return '';
    }
    function createTagItem(name) {
      var item = $('<li class="tag tag-' + namespace(name) + '" data-name="' + name + '"><i title="Remove Tag" class="fa fa-times remove"></i><a href="/tags/' + name + '">' + name + '</a></li>');
      list.append(item);
      item.find('.remove').on('click', function() {
        removeTag(item, name);
      });
    }
    function removeTag(self, name) {
      dropTag(self, name);
      history.unshift({type: -1, tag: name});
    }
    function dropTag(self, name) {
      tags.splice(tags.indexOf(name), 1);
      self.remove();
      value.val(tags.join(','));
      save();
    }
    function undo() {
      if (history.length) {
        var item = history.shift();
        if (item.type > 0) {
          dropTag(list.find('[data-name="' + item.tag + '"]'), item.tag);
        } else {
          pickupTag(item.tag);
          save();
        }
      }
    }
    function save() {
      me.trigger('tagschange');
      if (target && id) {
        ajax.post('update/' + target, function() {
          
        }, true, {
          id: id,
          field: 'tags',
          value: value.val()
        });
      }
    }
    
    function doSearch(name) {
      name = name.toLowerCase();
      if (name.length > 0) ajax.get('find/tags', function(json) {
        searchResults.empty();
        for (var i = json.results.length; i--; ) {
          var item = $('<li class="tag-' + namespace(json.results[i].name) + '"><span>' + json.results[i].name + '</span> (' + json.results[i].members + ')' + '</li>');
          item.on('click', function() {
            searchResults.removeClass('shown');
            var text = input.val().trim().split(/,|;/);
            text[text.length - 1] = $(this).find('span').text()
            for (var i = 0; i < text.length; i++) {
              appendTag(text[i]);
            }
            input.val('');
            save();
          });
          searchResults.append(item);
        }
        me[json.results.length ? 'addClass' : 'removeClass']('pop-out-shown');
      }, {
        'q': name
      });
    }
    var input = me.find('.input');
    var last_value = '';
    var handled_back = false;
    input.on('keydown', function(e) {
      if (e.which == KEY_ENTER || e.which == KEY_COMMA) {
        var text = input.val().trim().split(/,|;/);
        for (var i = 0; i < text.length; i++) {
          appendTag(text[i]);
        }
        input.val('');
        save();
        e.preventDefault();
        e.stopPropagation();
        handled_back = false;
      } else if (e.which == KEY_BACKSPACE) {
        if (!handled_back) {
          handled_back = true;
          var value = input.val();
          if (!value.length) {
            list.children('.tag').last().find('.remove').click();
          }
        }
      } else if (e.ctrlKey && e.which == 90) {
        undo();
        e.preventDefault();
        e.stopPropagation();
        handled_back = false;
      } else {
        handled_back = false;
      }
    });
    input.on('keyup', function() {
      handled_back = false;
    });
    input.on('mousedown', function(e) {
      e.stopPropagation();
    });
    var autocomplete = null;
    input.on('focus', function(e) {
      if (!autocomplete) autocomplete = setInterval(function() {
        var value = input.val();
        if (value != last_value) {
          last_value = value;
          doSearch(value.trim().split(/,|;/).reverse()[0]);
        }
      }, 1000);
    });
    input.on('blur', function() {
      clearInterval(autocomplete);
      autocomplete = null;
    });
    $(this).on('mouseup', function(e) {
      input.focus();
      e.preventDefault();
      e.stopPropagation();
    }).on('mousedown', function(e) {
      e.stopPropagation();
    })
  });
})();
var shares = {
  'facebook': 'http://www.facebook.com/sharer/sharer.php?href={url}',
  'twitter': 'https://twitter.com/intent/tweet?url={url}&via=ProjectVinyl&related=ProjectVInyl,Brony,Music',
  'googleplus': 'https://plus.google.com/u/0/share?url={url}&hl=en-GB&caption={title}',
  'tumblr': 'https://www.tumblr.com/widgets/share/tool?canonicalUrl={url}&posttype=video&title={title}&content={url}'
}
$('.share-buttons button').on('click', function() {
  var ref = shares[$(this).attr('data-type')];
  if (ref) {
    ref = ref.replace(/{url}/g, encodeURIComponent(document.location.href));
    ref = ref.replace(/{title}/g, encodeURIComponent($(this).parent().attr('data-caption')));
    window.open(ref, 'sharer', 'width=500px,height=450px,status=0,toolbar=0,menubar=0,addressbar=0,location=0');
  }
});
$('form.async').on('submit', function(e) {
  ajax.form($(this), e);
});
$(document).on('click', '.pop-out-toggle', function() {
  var me = $(this);
  var popout = $(this).closest('.popper');
  var popoutcontent = popout.find('.pop-out');
  me.on('click', function(e) {
    if (popout.length && !popout.hasClass('pop-out-shown')) {
      $('.pop-out-shown').removeClass('pop-out-shown');
      popout.addClass('pop-out-shown');
      popout.removeClass('pop-left');
      popout.removeClass('pop-right');
      
      var left = popoutcontent.offset().left;
      var right = left + popoutcontent.width();
      var width = $(window).width();
      
      if (right > width) {
        popout.addClass('pop-left');
      }
      if (left < 0 ) {
        popout.addClass('pop-right');
      }
    } else {
      $('.pop-out-shown').removeClass('pop-out-shown');
    }
    e.stopPropagation();
    e.preventDefault();
  });
  popout.on('mousedown', function(e) {
    e.stopPropagation();
  });
  me.click();
});
$(document).on('mousedown', function() {
  $('.pop-out-shown').removeClass('pop-out-shown');
});
(function() {
  function lookup(sender, popout, action, input, validate) {
    ajax.post(action + '/lookup', function(json) {
      popout.empty();
      for (var i = 0; i < json.content.length; i++) {
        var item = $('<li></li>');
        item.text(json.content[i][1] + ' (#' + json.content[i][0] + ')');
        item.attr('data-name', json.content[i][1]);
        item.on('mousedown', function() {
          input.val($(this).attr('data-name'));
          sender.removeClass('pop-out-shown');
        });
        popout.append(item);
      }
      sender[json.content.length ? 'addClass' : 'removeClass']('pop-out-shown');
      sender[json.reject ? 'addClass' : 'removeClass']('invalid');
    }, 0, {
      query: input.val(), validate: validate ? 1 : 0
    });
  }
  var autocomplete = null;
  $(document).on('focus', '.auto-lookup:not(.loaded) input', function() {
    var input = $(this);
    var me = input.parent();
    me.addClass('loaded');
    var popout = me.find('.pop-out');
    var action = me.attr('data-action');
    var last_value = null;
    var validate = me.hasClass('validate');
    input.on('blur', function() {
      clearInterval(autocomplete);
      autocomplete = null;
    });
    input.on('focus', function(e) {
      if (!autocomplete) autocomplete = setInterval(function() {
        var value = input.val();
        if (value != last_value) {
          last_value = value;
          lookup(me, popout, action, input, validate);
        }
      }, 1000);
    });
  });
})();
(function() {
  function count(me, offset) {
    var likes = me.attr('data-count');
    if (!likes) {
      likes = 0;
    } else {
      likes = parseInt(likes);
    }
    likes += offset;
    me.attr('data-count', likes);
    if (likes == 0) {
      me.find('span').remove();
    } else {
      var count = me.find('.count');
      if (!count.length) {
        me.append('<span> (<span class="count" >' + likes + '</span>)</span>');
      } else {
        count.text(likes);
      }
    }
    ajax.post(me.attr('data-action') + '/' + me.attr('data-id') + '/' + offset, function(json) {
      if (count) count.text(json.count);
    });
    return me;
  }
  function like() {
    var me = $(this);
    if (me.hasClass('liked')) {
      count(me, -1).removeClass('liked');
    } else {
      var other = me.parent().find('.liked');
      if (other.length) {
        count(other, -1).removeClass('liked');
      }
      count(me, 1).addClass('liked');
    }
  }
  function fave() {
    var me = $(this);
    me.toggleClass('starred');
    ajax.post(me.attr('data-action') + '/' + me.attr('data-id'), function(xml) {
      if (xml.added) {
        me.addClass('starred');
      } else {
        me.removeClass('starred');
      }
    });
  }
  $(document).on('click', 'button.action.like, button.action.dislike', like);
  $(document).on('click', 'button.action.star', fave);
})();
$(document).on('click', '.state-toggle', function(ev) {
  ev.preventDefault();
  var me = $(this);
  var state = me.attr('data-state');
  me.parent().toggleClass(state);
  me.text(me.attr('data-' + me.parent().hasClass(state)));
});
(function() {
  function toggle(sender, family, action, id, item_id, check_icon, uncheck_icon) {
    var action = sender.attr('data-target') + '/' + sender.attr('data-action');
    var family = sender.attr('data-family');
    var id = sender.attr('data-id');
    var item_id = sender.attr('data-item');
    var data = sender.attr('data-with');
    if (data) action += '?extra=' + $(data).val();
    var check_icon = sender.attr('data-checked-icon') || 'check';
    var uncheck_icon = sender.attr('data-unchecked-icon');
    var state = sender.attr('data-state');
    ajax.post(action, function(json) {
      if (family) {
        $('.action.toggle[data-family=' + family + '][data-id=' + id + ']').each(function() {
          var me = $(this);
          var uncheck = me.attr('data-unchecked-icon');
          var check = me.attr('data-checked-icon') || 'check';
          me.find('.icon').html(json[$(this).attr('data-action')] ? '<i class="fa fa-' + check + '"></i>' : (uncheck ? '<i class="fa fa-' + uncheck + '"></i>' : ''))
        });
      } else {
        sender.find('.icon').html(json.added ? '<i class="fa fa-' + check_icon + '"></i>' : (uncheck_icon ? '<i class="fa fa-' + uncheck_icon + '"></i>' : ''));
        if (state) {
          sender.parents(sender.attr('data-parent'))[json.added ? 'addClass' : 'removeClass'](state);
        }
      }
    }, false, {
      id: id, item: item_id
    });
  }
  $(document).on('click', '.action.toggle', function(e) {
    toggle($(this));
    e.preventDefault();
  });
})();
(function() {
  function init(me) {
    me.addClass('loaded');
    var action = me.attr('data-action');
    var url = me.attr('data-url');
    var id = me.attr('data-id');
    var callback = me.attr('data-callback');
    var popup;
    if (action == 'delete') {
      if (!popup) {
        popup = new Popup(me.attr('data-title'), me.attr('data-icon'), function() {
          this.content.append('<div class="message_content">Are you sure?</div><div class="foot"></div>');
          var ok = $('<button class="button-fw green">Yes</button>');
          var cancel = $('<button class="cancel button-fw blue" style="margin-left:20px;" type="button">No</button>');
          ok.on('click', function() {
            ajax.post(url, function(json) {
              if (json.ref) {
                document.location.replace(json.ref);
              } else if (callback) {
                window[callback](id, json);
              }
            });
            popup.close();
          });
          cancel.on('click', function() {
            popup.close();
          });
          this.content.find('.foot').addClass('center');
          this.content.find('.foot').append(ok);
          this.content.find('.foot').append(cancel);
          this.setPersistent();
          this.show();
        });
      } else {
        popup.show();
      }
    } else {
      popup = Popup.fetch(url, me.attr('data-title'), me.attr('data-icon'), me.hasClass('confirm-button-thin'));
      popup.setPersistent();
      
    }
    me.on('click', function(e) {
      popup.show();
      e.preventDefault();
    });
  }
  $(document).on('click', '.confirm-button:not(.loaded)', function(e) {
    init($(this));
    e.preventDefault();
  });
})();
(function() {
  var grabber;
  var floater;
  function moveFloater(e) {
    floater.css('top', e.pageY - floater.parent().offset().top);
  }
  function reorder(target, id, index) {
    ajax.post('update/' + target, function() {
      
    }, true, {
      id: id, index: index
    });
  }
  function grab(target, container, item) {
    container.addClass('ordering');
    container.find('.grabbed').removeClass('grabbed');
    floater = item.clone();
    item.addClass('grabbed');
    container.append(floater);
    var srcChilds = item.children();
    var dstChilds = floater.children();
    for (var i = 0; i < srcChilds.length; i++) {
      dstChilds.eq(i).css('width', srcChilds.eq(i).innerWidth());
    }
    var originalIndex = parseInt(item.attr('data-index'));
    floater.addClass('floater');
    floater.css('top', item.offset().top);
    $(document).one('mouseup', function(e) {
      floater.remove();
      floater = null;
      reorder(target, item.attr('data-id'), item.attr('data-index'));
      container.removeClass('ordering');
      container.find('.grabbed').removeClass('grabbed');
      container.children(':not(.floater)').off('mouseover');
      e.preventDefault();
      e.stopPropagation();
      $(document).off('mousemove', moveFloater);
      container.children().each(function(i) {
        $(this).attr('data-index', i);
      });
    });
    $(document).on('mousemove', moveFloater);
    container.children(':not(.floater)').on('mouseover', function() {
      $(this).after(item);
      var index = parseInt($(this).attr('data-index'));
      if (index <= originalIndex) index++;
      item.attr('data-index', index);
    });
  }
  
  $('.reorderable').each(function() {
    var orderable = $(this);
    var target = orderable.attr('data-target');
    orderable.find('.handle').on('mousedown', function(e) {
      var me = $(this).parent();
      grabber = function() {
        grab(target, orderable, me);
      };
      $(document).one('mousemove', grabber);
      e.preventDefault();
      e.stopPropagation();
    }).on('mouseup', '.reorderable .handle', function(e) {
      $(document).off('mousemove', grabber);
    });
  });
  $(document).on('click', '.removeable .remove', function(e) {
    var me = $(this).parent();
    if (me.hasClass('repaintable')) {
      ajax.post('delete/' + me.attr('data-target'), function(json) {
        paginator.repaint(me.closest('.paginator'), json);
      }, false, { id: me.attr('data-id') });
    } else {
      ajax.post('delete/' + me.attr('data-target'), function() {
        me.remove();
      }, true, { id: me.attr('data-id') });
    }
    e.preventDefault();
    e.stopPropagation();
  });
})();
var Popup = (function() {
  function Popup(title, icon, construct) {
    this.container = $('<div class="popup-container"></div>');
    this.dom = $('<div class="popup"><h1>' + title + '<a class="close" /></h1>');
    this.container.append(this.dom);
    this.content = $('<div class="content" />');
    this.fixed = false;
    this.x = this.y = -1;
    this.dom.append(this.content);
    if (typeof icon === 'string') {
      this.dom.find('h1').prepend('<i class="fa fa-' + icon + '" />');
    }
    if (typeof icon === 'function') construct = icon;
    var me = this;
    this.container.on('click mousedown mousup', function() {
      me.focus();
    });
    this.dom.find('.close').on('click', function() {
      me.close();
    });
    this.dom.find('h1').on('mousedown', function(ev) {
      me.grab(ev.pageX, ev.pageY);
      ev.preventDefault();
      ev.stopPropagation();
    });
    if (construct) construct.apply(this);
    return this;
  }
  Popup.fetch = function(resource, title, icon, thin) {
    return (new Popup(title, icon, function() {
      this.content.html('<div class="loader"><i class="fa fa-pulse fa-spinner" /></div>');
      if (thin) this.container.addClass('thin');
      var me = this;
      ajax(resource, function(xml, type, ev) {
        me.content.html(ev.responseText);
        me.content.find('.cancel').on('click', function() {
          me.close();
        });
        me.center();
      }, 1);
      this.show();
    }));
  }
  Popup.prototype = {
    setPersistent: function() {
      this.persistent = true;
    },
    focus: function() {
      if (!this.container.hasClass('focus')) {
        this.container.parent().append(this.container);
        this.fade.parent().append(this.fade);
        $('.popup-container.focus').removeClass('focus');
        this.container.addClass('focus');
      }
    },
    center: function() {
      this.x = ($(window).width() - this.container.width())/2 + $(window).scrollLeft();
      this.y = ($(window).height() - this.container.height())/2 + $(window).scrollTop();
      this.move(this.x, this.y);
    },
    bob: function(reverse, callback) {
      if (reverse) {
        this.container.css('transition', 'transform 0.5s ease, opacity 0.5s ease');
        this.container.css({
          'opacity': 0, 'transform': 'translate(0,30px)'
        });
      } else {
        this.container.css('transition', 'transform 0.5s ease, opacity 0.5s ease');
        timeoutOn(this, function() {
          this.container.css({
            'opacity': 1, 'transform': 'translate(0,0)'
          });
        }, 1);
      }
      timeoutOn(this, function() {
        if (callback) callback(this);
      }, 500);
    },
    show: function() {
      $('.popup-container.focus').removeClass('focus');
      this.container.addClass('focus');
      this.container.css({
        'opacity': 0, 'transform': 'translate(0,30px)'
      });
      this.container.css('display', '');
      $('body').append(this.container);
      if (this.x <= 0 || this.y <= 0) {
        this.center();
      }
      this.fade = $('<div style="opacity:0" />');
      $('.fades').append(this.fade);
      timeoutOn(this, function() {
        this.fade.css('opacity', 1);
      }, 1);
      this.bob();
    },
    close: function() {
      this.bob(1, function(me) {
        if (!me.persistent) {
          me.container.remove();
        } else {
          me.container.css('display', 'none');
        }
      });
      if (this.fade) {
        this.fade.css('opacity', 0);
        timeoutOn(this, function() {
          this.fade.remove();
        }, 500);
      }
    },
    setId: function(id) {
      this.container.attr('id', id);
      return this;
    },
    grab: function(x, y) {
      var me = this;
      var offX = x - this.container.offset().left;
      var offY = y - this.container.offset().top;
      this.dragging = function(ev) {
        me.move(ev.pageX - offX, ev.pageY - offY);
      };
      this.focus();
      $(document).on('mousemove', this.dragging);
      $(document).one('mouseup', function() {
        me.release();
      });
    },
    release: function() {
      if (this.dragging) {
        $(document).off('mousemove', this.dragging);
        this.dragging = null;
      }
    },
    move: function(x, y) {
      var scrollX = $(window).scrollLeft();
      var scrollY = $(window).scrollTop();
      if (this.fixed) {
        x -= scrollX;
        y -= scrollY;
        scrollX = 0;
        scrollY = 0;
      }
      if (y < 0) y = 0;
      if (x < 0) x = 0;
      if (x > $(window).width() - this.container.width() + scrollX) x = $(window).width() - this.container.width() + scrollX;
      if (y > $(window).height() - this.container.height() + scrollY) y = $(window).height() - this.container.height() + scrollY;
      this.container.css({top: this.y = y, left: this.x = x});
    },
    setFixed: function() {
      this.fixed = true;
      this.container.css('position', 'fixed');
      return this;
    }
  };
  return Popup;
})();

var paginator = (function() {
  function requestPage(context, page) {
    if (page == context.attr('data-page')) return;
    context.attr('data-page', page);
    page = parseInt(page);
    arguments = arguments || {};
    arguments.page = page;
    context.find('ul').addClass('waiting');
    context.find('.pagination .pages .button.selected').removeClass('selected');
    ajax.get(context.attr('data-type') + '?page=' + context.attr('data-page') + '&' + context.attr('data-args'), function(json) {
      populatePage(context, json);
    }, {});
  }
  function populatePage(context, json) {
    var container = context.find('ul');
    container.html(json.content);
    container.removeClass('waiting');
    context.attr('data-page', json.page);
    context.find('.pagination').each(function() {
      repaintPages($(this), json.page, json.pages);
    });
  }
  function repaintPages(context, page, pages) {
    var index = page > 4 ? page - 4 : 0;
    var id = context.attr('data-id');
    context.find('.pages .button').each(function() {
      if (index >= page + 4 || index > pages) {
        $(this).remove();
      } else {
        $(this).attr('data-page-to', index).attr('href', '#/' + id + '/' + (index + 1)).text(index + 1);
        if (index == page) {
          $(this).addClass('selected');
        }
      }
      index++;
    });
    context = context.find('.pages');
    while (index <= page + 4 && index <= pages) {
      context.append('<a class="button' + (index == page ? ' selected' : '') + '" data-page-to="' + index + '" href="#/' + id + '/' + ++index + '">' + index + '</a> ');
    }
    document.location.hash = '/' + id + '/' + (page + 1);
  }
  $(document).on('click', '.pagination .pages .button, .pagination .button.left, .pagination .button.right', function() {
    paginator.goto($(this));
  });
  var hash = document.location.hash;
  var page = -2;
  var match;
  if (match = hash.match(/#\/([^\/]+)/)) {
    var id = match[1];
    hash = hash.replace('/' + id + '/', '');
    if (hash.indexOf('#first') == 0) {
      page = 0;
    } else if (hash.indexOf('#last') == 0) {
      page = -1;
    } else {
      page = parseInt(hash.match(/#([0-9]+)/)[1]);
    }
    if (page > -2) {
      $(document).ready(function() {
        var pagination = $('.pagination[data-id=' + id +']');
        if (pagination.length) {
          requestPage(pagination.closest('.paginator'), page - 1);
        } else {
          var tab_switch = $('.tab-set.async a.button[data-target=' + id + ']');
          if (tab_switch.length) {
            tab_switch.attr('data-page', page - 1);
            tab_switch.click();
          }
        }
      });
    }
  }
  return {
    repaint: function(context, json) {
      context.find('.pagination .pages .button.selected').removeClass('selected');
      populatePage(context, json);
    },
    goto: function(button) {
      requestPage(button.closest('.paginator'), button.attr('data-page-to'));
    }
  }
})();

$(document).on('focus', 'label input, label select', function() {
  $(this).closest('label').addClass('focus');
}).on('blur', 'label input, label select', function() {
  $(this).closest('label').removeClass('focus');
});

function error(message) {
  new Popup('Error', 'warning', function() {
    this.content.append('<div class="message_content">' + message + '</div><div class="foot"></div>');
    var ok = $('<button class="right button-fw">Ok</button>');
    var me = this;
    ok.on('click', function() {
      me.close();
    });
    this.content.find('.foot').append(ok);
    this.show();
  });
}

function postComment(sender, thread_id, order, report_state) {
  sender = $(sender).parent();
  var input = sender.find('textarea, input.comment-content');
  var comment = input.val();
  if (!comment.length) {
    return error('You have to type something to post');
  }
  sender.addClass('posting');
  var data = {
    thread: thread_id,
    order: order,
    comment: comment
  };
  if (report_state) data.report_state = report_state;
  ajax.post('comments/new', function(json) {
    sender.removeClass('posting');
    paginator.repaint($('#thread-' + thread_id).closest('.paginator'), json);
    scrollTo('#comment_' + json.focus);
    input.val('').change();
  }, 0, data);
}

function postChat(sender, thread_id, order, report_state) {
  sender = $(sender).parent();
  var input = sender.find('textarea, input.comment-content');
  var comment = input.val();
  if (!comment.length) {
    return;
  }
  sender.addClass('posting');
  var data = {
    thread: thread_id,
    order: order,
    comment: comment,
    quick: true
  };
  if (report_state) data.report_state = report_state;
  ajax.post('comments/new', function(json) {
    sender.removeClass('posting');
    $('#chat').html(json.content);
    scrollTo('#comment_' + json.focus, $('#comments-container .scroll-container'));
    input.val('').change();
  }, 0, data);
}

function editComment(sender) {
  sender = $(sender).parent();
  ajax.post('comments/edit', function(html) {
    sender.removeClass('editing');
  }, 1, {
    id: sender.attr('data-id'),
    comment: sender.find('textarea, input.comment-content').val()
  });
}

function removeComment(id, json) {
  id = $('#comment_' + id);
  if (json.content) {
    return id.after(json.content).remove();
  }
  if (id.length) {
    id.css({
      'min-height': 0,
      height: id.height(), overflow: 'hidden'
    }).css('transition', '0.5s ease all').css({
      opacity: 0, height: 0
    });
    setTimeout(function() {
      id.remove();
    }, 500);
  }
}


$(document).ready(function() {
  if (document.location.hash.indexOf('#comment_') == 0) {
    lookupComment(document.location.hash.split('_')[1]);
  }
});

function lookupComment(comment_id) {
  var comment = $('#comment_' + comment_id);
  if (comment.length) {
    scrollTo(comment).addClass('highlight');
  } else {
    var pagination = $('.comments').parent();
    ajax.get(pagination.attr('data-type') + '?comment=' + comment_id + '&' + pagination.attr('data-args'), function(json) {
      paginator.repaint(pagination, json);
      scrollTo($('#comment_' + comment_id)).addClass('highlight');
    });
  }
}

function findComment(sender) {
  sender = $(sender);
  var container = sender.parent();
  var parent = sender.attr('href');
  if (!$(parent).length) {
    ajax.get('comments/get', function(html) {
      container.parent().prepend(html);
      $('.comment.highlight').removeClass('highlight');
      scrollTo(parent).addClass('highlight').addClass('inline');
    }, {
      id: sender.attr('data-comment-id')
    }, 1);
  } else {
    parent = $(parent);
    if (parent.hasClass('inline')) {
      container.parent().prepend(parent);
    }
    $('.comment.highlight').removeClass('highlight');
    scrollTo(parent).addClass('highlight');
  }
}

var decode_entities = (function() {
  var div = document.createElement('DIV');
  return function(string) {
    div.innerHTML = string;
    return div.innerText;
  }
})();

function replyTo(sender) {
  sender = $(sender).parent();
  textarea = sender.closest('.page, body').find('.post-box textarea');
  textarea.focus();
  textarea.val('>>' + sender.attr('data-o-id') + ' [q]\n' + decode_entities(sender.attr('data-comment')) + '\n[/q]' + textarea.val());
  textarea.change();
}

function markRead() {
  messageOperation({
    id: 'read', callback: function() {
      var me = $(this);
      me.removeClass('unread');
      me.find('button.button-bub.toggle i').attr('class', 'fa fa-star-o');
    }
  });
}

function markUnRead() {
  messageOperation({
    id: 'unread', callback: function() {
      var me = $(this);
      me.addClass('unread');
      me.find('button.button-bub.toggle i').attr('class', 'fa fa-star');
    }
  });
}

function markDeleted() {
  messageOperation({
    id: 'delete', callback: function(me, json) {
      paginator.repaint(me.closest('.paginator'), json);
    }
  });
}

function messageOperation(action) {
  var checks = $('input.message_select:checked');
  if (checks.length > 0) {
    var ids = [];
    checks.each(function() {
      ids.push(this.value);
    });
    ajax.post('/messages/action', function(json) {
      if (json.content) {
        action.callback(checks, json);
      } else {
        checks.parents('li.thread').each(action.callback);
      }
    }, false, {
      ids: ids.join(';'), op: action.id
    });
  }
}

$(document).on('change', '.message_select', function() {
  if ($('input.message_select:checked').length) {
    $('#batch_ops').removeClass('disabled');
  } else {
    $('#batch_ops').addClass('disabled');
  }
});
$(document).on('click', '.reply-comment', function() {
  replyTo(this);
});
$(document).on('click', '.edit-comment-submit', function() {
  editComment(this);
});
$(document).on('click', '.comment .mention', function(ev) {
  findComment(this);
  ev.preventDefault();
});
$(document).on('click', '.spoiler', function() {
  $(this).toggleClass('revealed');
});
$(document).on('click', '.tab-set li.button:not([data-disabled])', function() {
  var me = $(this);
  if (!me.hasClass('selected')) {
    var other = me.parent().find('.selected');
    other.removeClass('selected');
    me.addClass('selected');
    $('div[data-tab=' + other.attr('data-target') + ']').removeClass('selected').trigger('tabblur');
    $('div[data-tab=' + me.attr('data-target') + ']').addClass('selected').trigger('tabfocus')
  }
});
$(document).on('click', '.tab-set.async a.button:not([data-disabled])', function(e) {
  var me = $(this);
  if (!me.hasClass('selected')) {
    var parent = me.parent();
    var other = parent.find('.selected');
    other.removeClass('selected');
    me.addClass('selected');
    var holder = $('.tab[data-tab=' + parent.attr('data-target') + ']');
    holder.addClass('waiting');
    ajax.get(parent.attr('data-url'), function(json) {
      holder.html(json.content);
      holder.removeClass('waiting');
    }, {
      type: me.attr('data-target'), page: (me.attr('data-page') || 0)
    });
  }
  e.preventDefault();
});

$(document).on('touchstart', '.drop-down-holder:not(.hover)', function(e) {
  var me = $(this);
  me.addClass('hover');
  e.preventDefault();
  e.stopPropagation();
  var lis = me.find('a, li');
  lis.on('touchstart', function(e) {
    e.stopPropagation();
  });
  function clos(e) {
    me.off('touchstart touchmove');
    me.removeClass('hover');
    lis.off('touchstart');
    e.preventDefault();
    e.stopPropagation();
  }
  me.one('touchstart touchmove', clos);
  $(document).one('touchstart touchmove', clos);
});

(function() {
  var hover_timeout = null;
  function openUsercard(sender, usercard) {
    $('.hovercard.shown').removeClass('shown');
    sender.append(usercard);
    if (hover_timeout) {
      clearTimeout(hover_timeout);
    }
    setTimeout(function() {
      usercard.addClass('shown');
      hover_timeout = setTimeout(function() {
        $('.user-link:not(:hover) .hovercard.shown').removeClass('shown');
      }, 500);
    }, 500);
  }
  $(document).on('mouseenter', '.user-link', function() {
    var sender = $(this);
    var id = sender.attr('data-id');
    var usercard = $('.hovercard[data-id=' + id + ']');
    if (!usercard.length) {
      usercard = $('<div class="hovercard" data-id="' + id + '"></div>');
      usercard.on('mouseenter', function(ev) {
        ev.stopPropagation();
      });
      sender.append(usercard);
      ajax.get('artist/hovercard', function(html) {
        usercard.html(html);
        openUsercard(sender, usercard);
      }, {id: id}, 1);
    } else {
      openUsercard(sender, usercard);
    }
  });
  $(document).on('mouseleave', '.user-link', function() {
    $('.hovercard.shown').toggleClass('shown');
  });
})();

function lazyLoad(button) {
  var target = $('#' + button.attr('data-target'));
  var page = parseInt(button.attr('data-page')) + 1;
  button.addClass('working');
  ajax.get(button.attr('data-url'), function(json) {
    button.removeClass('working');
    if (json.page == page) {
      target.append(json.content);
      button.attr('data-page', page);
    } else {
      button.remove();
    }
  }, {
    page: page,
    id: button.attr('data-id')
  });
}

function timeoutOn(target, func, time) {
  return setTimeout(function() {
    func.apply(target);
  }, time);
}

function slideOut(holder) {
  holder.css('min-height', holder.find('.group.active').height());
  holder.css('max-height', holder.find('.group.active').height() + 10);
  if (holder.hasClass('shown')) {
    holder.removeClass('shown');
  } else {
    $('.slideout.shown').removeClass('shown');
    holder.addClass('shown');
  }
  return holder;
}

$(document).on('click', '.slider-toggle', function(e) {
  var me = $(this);
  var holder = $(me.attr('data-target'));
  if (me.hasClass('loadable') && !me.hasClass('loaded')) {
    me.addClass('loaded');
    ajax(me.attr('data-url'), function(json) {
      holder[0].innerHTML = json.content;
			holder.find('script').each(function() {
				var cs = document.createElement('SCRIPT');
				cs.textContent = '(function(){' + this.innerText + '}).apply({})';
				cs.onload = cs.onerror = function() {
					cs.parentNode.removeChild(cs);
				};
				document.head.appendChild(cs);
			});
      slideOut(holder);
    });
  } else {
    slideOut(holder);
  }
  e.preventDefault();
});
$(document).on('click', '.load-more button', function() {
  lazyLoad($(this));
});
$(document).on('click', '.mix a', function(e) {
  var ref = $(this).attr('href');
  document.location.replace(ref + '&t=' + $('#video .player')[0].getPlayerObj().video.currentTime);
  e.preventDefault();
});