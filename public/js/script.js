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
});
var ajax = (function() {
  var token = $('meta[name=csrf-token]').attr('content');
  function request(method, resource, callback, data, direct) {
    $.ajax({
      type: method,
      datatype: 'json',
      url: resource,
      success: direct ? callback : function(xml, type, ev) {
        callback(JSON.parse(ev.responseText));
      },
      error: function(d) {
        console.log(d.responseText);
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
                  message.text(Math.floor(percentage) + '%');
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
        form.addClass('uploading');
      },
      success: callbacks.success || function (data) {
        if (data.ref) {
          document.location.href = data.ref;
        }
      },
      error: function(e, err, msg) {
        form.removeClass('waiting').addClass('error');
        if (callbacks.error) return callbacks.error(message, err, msg);
        message.text(err + ": " + msg);
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
    text = text.replace(/\[icon\]([^\[]+)\[\/icon\]/g, '<i class="fa fa-fw fa-$1"></i>');
    text = text.replace(/\n/g, '<br>').replace(/\[([\/]?([buis]|sup|sub|hr))\]/g, '<$1>').replace(/\[([\/]?)q\]/g, '<$1blockquote>');
    text = text.replace(/\[url=([^\]]+)]/g, '<a href="$1">').replace(/\[\/url]/g, '</a>');
    text = text.replace(/([^">]|[\s]|<[\/]?br>|^)(http[s]?:\/\/[^\s\n<]+)([^"<]|[\s\n]|<br>|$)/g, '$1<a data-link="1" href="$2">$2</a>$3');
    text = text.replace(/\[img\]([^\[]+)\[\/img\]/g, '<img src="$1" style="max-width:100%"></img>');
    var i = emoticons.length;
    while (i--) {
      text = text.replace(new RegExp(':' + emoticons[i] + ':', 'g'), '<img class="emoticon" src="/emoticons/' + emoticons[i] + '.png">');
    }
    return text;
  }
  function poor(text) {
    text = text.replace(/<i class="fa fa-fw fa-([^"]+)"><\/i>/g, '[icon]$1[/icon]');
    text = text.replace(/<br>/g, '\n').replace(/<([\/]?([buis]|sup|sub|hr))>/g, '[$1]').replace(/<([\/]?)blockquote>/g, '[$1q]');
    text = text.replace(/<a data-link="1" href="([^"]+)">[^<]*<\/a>/g, '$1');
    text = text.replace(/<a href="([^"]+)">/g, '[url=$1]').replace(/<\/a>/g, '[/url]');
    text = text.replace(/<\/img>/g, '').replace(/<img src="([^"]+)" style="max-width:100%">/g, '[img]$1[/img]');
    var i = emoticons.length;
    while (i--) {
      text = text.replace(new RegExp('<img class="emoticon" src="/emoticons/' + emoticons[i] + '.png">', 'g'), ':' + emoticons[i] + ':');
    }
    return text;
  }
  function initEditable(holder, content, short) {
    var textarea = holder.find('.input');
    var lastHeight = 0;
    if (!textarea.length) {
      if (short) {
        textarea = $('<input class="input" />');
        textarea.css('height', content.innerHeight());
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
  function handleSpecialKeys(key, callback) {
    if (key == 66) {
      callback('b');
    } else if (key == 85) {
      callback('u');
    } else if (key == 73) {
      callback('i');
    } else if (key == 83) {
      callback('s');
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
      if (selected.indexOf(open) != -1 || selected.indexOf(close) != -1) {
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
      textarea.val(poor(content.html()));
      holder.addClass('editing');
    } else {
      if (!text || !text.length || text == emptyMessage.toLowerCase()) {
        content.text(emptyMessage);
      }
      content.html(rich(textarea.val()));
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
  $('textarea.comment-content').trigger('change');
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
          me.trigger('accept', {title: title, mime: input[0].files[0].type});
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
    var me = $(this);
    me.find('.values').remove();
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
    for (var i = 0, len = tags.length; i < len; i++) {
      createTagItem(tags[i]);
    }
    value.val(tags.join(','));
    function appendTag(name) {
      name = name.trim().toLowerCase().replace(/[^ a-z0-9\/&\-:]/g, '');
      if (name.length) {
        if (tags.indexOf(name) == -1) {
          tags.push(name);
          value.val(tags.join(','));
          createTagItem(name);
        }
      }
    }
    function createTagItem(name) {
      var item = $('<li class="tag"><i title="Remove Tag" class="fa fa-times remove"></i><a href="/tags/' + name + '">' + name + '</a></li>');
      list.append(item);
      item.find('.remove').on('click', function() {
        removeTag(item, name);
      });
    }
    function removeTag(self, name) {
      tags.splice(tags.indexOf(name), 1);
      self.remove();
      value.val(tags.join(','));
      save();
    }
    function save() {
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
          var item = $('<li style="color:' + json.results[i].colour + ';"><span>' + json.results[i].name + '</span> (' + json.results[i].members + ')' + '</li>');
          item.on('click', function() {
            searchResults.removeClass('shown');
            var text = input.val().trim().split(/,|;/);
            text[text.length - 1] = $(this).find('span').text();
            for (var i = 0; i < text.length; i++) {
              appendTag(text[i]);
            }
            input.val('');
            save();
          });
          searchResults.append(item);
        }
        searchResults[json.results.length ? 'addClass' : 'removeClass']('shown');
      }, {
        'q': name
      });
    }
    var input = me.find('.input');
    var last_value = '';
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
      }
    })
    input.on('keyup focus', function(e) {
      if (e.which != KEY_ENTER && e.which != KEY_COMMA) {
        var value = input.val();
        if (!value.length) {
          if (e.which == KEY_BACKSPACE) {
            list.children('.tag').last().find('.remove').click();
          }
        }
      }
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
      clearIntervel(autocomplete);
      autocomplete = null;
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
$('.pop-out-toggle').on('click', function(e) {
  var popout = $(this).closest('.popper').find('.pop-out');
  if (popout.length && !popout.hasClass('shown')) {
    popout.addClass('shown');
    e.stopPropagation();
  }
});
$('.pop-out').on('mousedown', function(e) {
  e.stopPropagation();
});
$(document).on('mousedown', function() {
  $('.pop-out.shown').removeClass('shown');
});
(function() {
  function lookup(popout, action, input) {
    ajax.post(action + '/lookup', function(json) {
      popout.empty();
      for (var i = 0; i < json.content.length; i++) {
        var item = $('<li></li>');
        item.text(json.content[i][1] + ' (#' + json.content[i][0] + ')');
        item.attr('data-name', json.content[i][1]);
        item.on('click', function() {
          input.val($(this).attr('data-name'));
          popout.removeClass('shown');
        });
        popout.append(item);
      }
      popout[json.content.length ? 'addClass' : 'removeClass']('shown');
    }, 0, { query: input.val() });
  }
  $('.auto-lookup').each(function() {
    var popout = $(this).find('.pop-out');
    var input = $(this).find('input');
    var action = $(this).attr('data-action');
    input.on('keyup', function() {
      lookup(popout, action, input);
    })
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
  function toggle(sender, action, id, item_id) {
    ajax.post(action, function(json) {
      sender.find('.icon').html(json.added ? '<i class="fa fa-check"></i>' : '');
    }, false, {
      id: id, item: item_id
    });
  }
  $('.action.toggle').each(function() {
    var me = $(this);
    var target = me.attr('data-target') + '/' + me.attr('data-action');
    var id = me.attr('data-id');
    var item = me.attr('data-item');
    me.on('click', function(e) {
      toggle(me, target, id, item);
    });
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
          var ok = $('<button>Ok</button>');
          var cancel = $('<button class="right cancel" type="button">Cancel</button>');
          ok.on('click', function() {
            ajax.post(url, function(json) {
              if (json.ref) {
                document.location.replace(json.ref);
              } else  if (callback) {
                window[callback](id);
              }
            });
            popup.close();
          });
          cancel.on('click', function() {
            popup.close();
          });
          this.content.find('.foot').append(ok);
          this.content.find('.foot').append(cancel);
          this.setPersistent();
          this.show();
        });
      } else {
        popup.show();
      }
    } else {
      popup = Popup.fetch(url, me.attr('data-title'), me.attr('data-icon'));
      popup.setPersistent();
    }
    me.on('click', function() {
      popup.show();
    });
  }
  $(document).on('click', '.confirm-button:not(.loaded)', function() {
    init($(this));
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
    orderable.find('.remove').on('click', function(e) {
      var me = $(this).parent();
      ajax.post('delete/' + target, function() {
        me.remove();
      }, true, { id: $(this).attr('data-id') });
      e.preventDefault();
      e.stopPropagation();
    });
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
  Popup.fetch = function(resource, title, icon) {
    return (new Popup(title, icon, function() {
      this.content.html('<div class="loader"><i class="fa fa-pulse fa-spinner" /></div>');
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
    context.find('.pages .button').each(function() {
      if (index > page + 4 || index > pages) {
        $(this).remove();
      } else {
        $(this).attr('data-page-to', index).attr('href', '#/page/' + (index + 1)).text(index + 1);
        if (index == page) {
          $(this).addClass('selected');
        }
      }
      index++;
    });
    context = context.find('.pages');
    while (index <= page + 4 && index <= pages) {
      context.append('<a class="button" data-page-to="' + index + '" href="#/page/' + ++index + '">' + index + '</a> ');
    }
    document.location.hash = '/page/' + (page + 1);
  }
  $(document).on('click', '.pagination .pages .button, .pagination .button.left, .pagination .button.right', function() {
    paginator.goto($(this));
  });
  var hash = document.location.hash;
  var page = -2;
  if (hash == '#first') page = 0;
  if (hash == '#last') page = -1;
  if (hash.indexOf('#/page/') == 0) {
    page = parseInt(hash.match(/#\/page\/([0-9]*)/)[1]);
  }
  if (page > -2) {
    $(document).ready(function() {
      requestPage($('.paginator'), page - 1);
    });
  }
  return {
    repaint: function(context, json) {
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
    var ok = $('<button class="right">Ok</button>');
    var me = this;
    ok.on('click', function() {
      me.close();
    });
    this.content.find('.foot').append(ok);
    this.show();
  });
}

function postComment(sender, thread_id) {
  sender = $(sender).parent();
  sender.addClass('posting');
  ajax.post('comments/new', function(json) {
    sender.removeClass('posting');
    paginator.repaint($('#thread-' + thread_id).closest('.paginator'), json);
    scrollTo('#comment_' + json.focus);
    sender.find('textarea').val('').change();
  }, 0, {
    thread: thread_id,
    comment: sender.find('textarea').val()
  });
}

function editComment(sender) {
  sender = $(sender).parent();
  ajax.post('comments/edit', function(html) {
    sender.removeClass('editing');
  }, 1, {
    id: sender.attr('data-id'),
    comment: sender.find('textarea').val()
  });
}

function removeComment(id) {
  id = $('#comment_' + id);
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
  textarea = sender.closest('.page').find('.post-box textarea');
  textarea.focus();
  textarea.val('>>' + sender.attr('data-o-id') + ' [q]\n' + decode_entities(sender.attr('data-comment')) + '\n[/q]' + textarea.val());
  textarea.change();
}

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
  ajax.get(button.attr('data-type'), function(json) {
    button.removeClass('working');
    if (json.page == page) {
      target.append(json.content);
      button.attr('data-page', page);
    } else {
      button.remove();
    }
  }, {
    page: page,
    artist: button.attr('data-id')
  });
}

function timeoutOn(target, func, time) {
  return setTimeout(function() {
    func.apply(target);
  }, time);
}

$(document).on('click', '.load-more button', function() {
  lazyLoad($(this));
});