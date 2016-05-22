$(window).ready(function () {
	function scroller() {
		var top = window.scrollY;
		if (top <= 200) banner.css('background-position', 'top calc(50% + ' + (top*0.5) + 'px) center');
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
var thumbnail = (function() {
  function thumb(holder, data) {
    return $('<li>\
							<a class="thumb" style="background-image:url(\'' + data.cover + '\');" href="view?' + data.id + '/' + data.title + '">\
								<div>' + data.title + '</div>\
							</a>\
						</li>').prependTo(holder);
  }
  function user(holder, data) {
    return thumb(holder, data).append(initDate($('<span class="date underline"><span>3 days ago</span></span>'), data.updated));
  }
  function album(holder, data) {
    return $('<li>\
                      <a class="thumb stack" href="album?' + data.id + '/' + data.title + '">\
							          <span style="background-image:url(\'' + data.thumb['0'] + '\');" class="stack-item item-1">\
								          <span style="background-image:url(\'' + data.thumb['1'] + '\');" class="stack-item item-2"></span>\
							          </span>\
						          </a>\
						          <div class="title">' + data.title + '</div>\
                    </li>').prependTo(holder).append(initDate($('<span class="date underline"><span>3 days ago</span></span>'), data.updated));
  }
  function playlist(holder, data) {
    return $('<a href="view?' + data.id + '/' + data.title + '">\
                      ' + (holder.hasClass('reorderable') ? '<div class="handle"><i class="fa fa-ellipsis-v" /></div>' : '') + '\
                      <div class="title">' + data.title + '</div>\
                      <div class="duration">' + data.duration + '</div>\
                      <div class="author"><span>' + data.author + '</span></div>\
                      ' + (holder.hasClass('reorderable') ? '<div class="remove" title="Remove"><span><i class="fa fa-times" /></span></div>' : '') + '\
                    </a>').prependTo(holder);
  }
  function call(holder, data, func) {
    return holder ? func(holder, data) : {
      'all': function(holder, items) {
        for (var i = items.length; i--; ) func(holder, items[i]);
      }
    };
  }
  return {
    thumb: function(holder, data) {return call(holder, data, thumb);},
    user: function(holder, data) {return call(holder, data, user);},
    album: function(holder, data) {return call(holder, data, album);},
    playlist: function(holder, data) {return call(holder, data, playlist);}
  }
})();
var ajax = (function() {
  var token = $('meta[name=csrf-token]').attr('content');
  function request(method, resource, callback, data, direct) {
    $.ajax({
      type: method,
      datatype: 'json',
      url: '/ajax/' + resource,
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
    request('GET', resource, callback, {}, direct);
  }
  result.post = function(resource, callback, direct) {
    request('POST', resource, callback, {
      authenticity_token: token
    }, direct);
  }
  return result;
})();
var scrollTo = (function() {
  function goto(pos) {
    $('html, body').animate({
      scrollTop: pos.top,
      scrollLeft: pos.left
    });
  }
  function scrollIntoView() {
    var win = $(window);
    var me = $(this);
    var offset = me.offset();
    lastPos = {
      top: win[0].scrollTop, left: win[0].scrollLeft, flag: 1
    }
    if (offset.top + me.height() > win.height()) {
      offset.top -= me.height()/2 + win.height()/2;
      offset.left -= me.width()/2 + win.width()/2;
      goto(offset)
    }
  };
  var lastPos = {top: 0, left: 0, flag: 0};
  var result = function(el) {
    return scrollIntoView.apply(el);
  };
  result.toggle = function(el) {
    if (lastPos.flag) {
      goto(lastPos);
      lastPos = {top: 0, left: 0, flag: 0};
    } else {
      scrollIntoView.apply(el);
    }
  };
  return result;
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
  $(document).on('contentload', fixFonts);
  return resizeFont;
})();
var BBC = (function() {
  var active = null;
  var emptyMessage = 'A description has not been written yet.';
  function rich(text) {
    text = text.replace(/\n/g, '<br>').replace(/\[([buis])\]/g, '<$1>').replace(/\[\/([buis])\]/g, '</$1>');
    var i = emoticons.length;
    while (i--) {
      text = text.replace(new RegExp(':' + emoticons[i] + ':', 'g'), '<img class="emoticon" src="/emoticons/' + emoticons[i] + '.png">');
    }
    return text;
  }
  function poor(text) {
    text = text.replace(/<br>/g, '\n').replace(/<([buis])>/g, '[$1]').replace(/<\/([buis])>/g, '[/$1]');
    var i = emoticons.length;
    while (i--) {
      text = text.replace(new RegExp('<img class="emoticon" src="/emoticons/' + emoticons[i] + '.png">', 'g'), ':' + emoticons[i] + ':');
    }
    return text;
  }
  function toggleEdit(editing, holder, content) {
    var text = content.text().toLowerCase().trim();
    var textarea = holder.find('.input');
    if (!editing) {
      if (!textarea.length) {
        if (holder.hasClass('short')) {
          textarea = $('<input class="input" />');
          textarea.css('height', content.innerHeight());
          content.after(textarea);
        } else {
          textarea = $('<textarea class="input" />');
          textarea.css('height', content.innerHeight() + 20);
          textarea.on('keydown keyup', function(ev) {
            textarea.css('height', 0);
            textarea.css('height', textarea[0].scrollHeight + 20);
          });
          content.after(textarea);
        }
      }
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
  function deactivate(button) {
    active = null;
    button.trigger('click');
  }
  $('.editable').each(function() {
    var editing = false;
    var me = $(this);
    var content = me.children('.content');
    var button = me.children('.edit');
    button.on('click', function() {
      if (active && active != button) deactivate(active);
      editing = toggleEdit(editing, me, content);
      active = editing ? button : null;
    });
    me.on('click', function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
    });
  });
  $(document).on('click', function() {
    if (active && !active.closest('.editable').is(':hover')) deactivate(active);
  });
  return {
    rich: rich, poor: poor
  }
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
    ajax.post('/' + me.attr('data-action') + '/' + me.attr('data-id') + '/' + offset, function(xml) {
      count.text(xml.count);
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
    $(this).toggleClass('starred');
  }
  $(document).on('click', 'button.action.like, button.action.dislike', like);
  $(document).on('click', 'button.action.star', fave);
})();
(function() {
  var grabber;
  var floater;
  function moveFloater(e) {
    floater.css('top', e.pageY - floater.parent().offset().top);
  }
  function grab(container, item) {
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
    floater.addClass('floater');
    floater.css('top', item.offset().top);
    $(document).one('mouseup', function(e) {
      floater.remove();
      floater = null;
      container.removeClass('ordering');
      container.find('.grabbed').removeClass('grabbed');
      container.children(':not(.floater)').off('mouseover');
      e.preventDefault();
      e.stopPropagation();
      $(document).off('mousemove', moveFloater);
    });
    $(document).on('mousemove', moveFloater);
    container.children(':not(.floater)').on('mouseover', function() {
      $(this).after(item);
    });
  }
  $(document).on('click', '.reorderable .handle', function(e) {
    e.preventDefault();
  });
  $(document).on('mousedown', '.reorderable .handle', function(e) {
    var me = $(this).parent();
    var reorderable = me.closest('.reorderable');
    grabber = function() {
      grab(reorderable, me);
    };
    $(document).one('mousemove', grabber);
    e.preventDefault();
    e.stopPropagation();
  });
  $(document).on('mouseup', '.reorderable .handle', function(e) {
    $(document).off('mousemove', grabber);
  });
  $(document).on('click', '.reorderable .remove', function(e) {
    $(this).parent().remove();
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
    this.dom.find('.close').on('click', function() {
      me.close();
    });
    this.dom.find('h1').on('mousedown', function(ev) {
      me.grab(ev.clientX, ev.clientY);
      ev.preventDefault();
      ev.stopPropagation();
    });
    if (construct) construct.apply(this);
  }
  Popup.fetch = function(resource, title, icon) {
    return (new Popup(title, icon, function() {
      this.content.html('<i class="fa fa-spin fa-spinner />');
      var me = this;
      ajax(resource, function(xml, type, ev) {
        me.content.html(ev.responseText);
      }, 1);
      this.show();
    }));
  }
  Popup.prototype = {
    show: function() {
      $('body').append(this.container);
      if (this.x < 0 || this.y < 0) {
        this.x = ($(window).width() - this.container.width())/2;
        this.y = ($(window).height() - this.container.height())/2;
        this.move(this.x, this.y);
      }
    },
    close: function() {
      this.container.remove();
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
        me.move(ev.clientX - offX, ev.clientY - offY);
      };
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
      if (this.fixed) {
        x -= $(window).scrollLeft();
        y -= $(window).scrollTop();
      }
      if (y < 0) y = 0;
      if (x < 0) x = 0;
      if (x > $(window).width() - this.container.width()) x = $(window).width() - this.container.width();
      if (y > $(window).height() - this.container.height()) y = $(window).height() - this.container.height();
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
function descriptive(milli) {
  if (milli >= 60000) {
    milli = Math.floor(milli / 60000);
    if (milli >= 60) {
      milli = Math.floor(milli / 60);
      if (milli >= 24) {
        milli = Math.floor(milli / 24);
        if (milli >= 365) {
          milli = Math.floor(milli / 365);
          return 'over ' + milli + ' years ago';
        }
        return milli + ' days ago';
      }
      return milli + ' hours ago';
    }
    return milli + ' minutes ago';
  }
  return 'a few seconds ago';
}
function initDate(el, date) {
  if ($.type(date) === 'string') date = parseInt(date);
  el.attr('title', (new Date(date)).toString());
  el.text(descriptive(Date.now() - date));
  return el;
}
function smartJoin(arr, pattern, separator) {
  var result = '', len = arr.length;
  separator = separator || ',';
  while (len--) {
    if (result.length) result = separator + result;
    if (arr[len]) result = (arr[len] + '').replace(/(.*)/, pattern) + result;
  }
  return result;
}
$(document).on('focus', 'label input, label select', function() {
  $(this).closest('label').addClass('focus');
}).on('blur', 'label input, label select', function() {
  $(this).closest('label').removeClass('focus');
});