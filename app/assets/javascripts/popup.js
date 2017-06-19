import { ajax } from './ajax.js';
import { scrollTo } from './uiscroll.js';
import { Key } from './utilities.js';

var INSTANCES = [];
var win = $(window);

win.on('resize', () => INSTANCES.forEach(i => i.resize()));
win.on('keydown', function(e) {
  if (INSTANCES.length && !$('input:focus, textarea:focus, button:focus, .button.focus').length) {
    var c = $('.popup-container.focus')[0];
    if (c) c.instance.handleShortcut(e);
  }
});

function timeoutOn(target, func, time) {
  return setTimeout(func.bind(target), time);
};

function Popup(title, icon, construct) {
  var self = this;
  
  this.container = $('<div class="popup-container"></div>');
  this.container[0].instance = this;
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
  
  this.container.on('click mousedown mousup', function() {
    self.focus();
  });
  this.dom.find('.close').on('click touchend', function() {
    self.close();
  });
  this.dom.find('h1').on('mousedown', function(ev) {
    self.grab(ev.pageX, ev.pageY);
    ev.preventDefault();
    ev.stopPropagation();
  });
  this.dom.find('h1').on('touchstart', function(ev) {
    var x = ev.originalEvent.touches[0].pageX || 0;
    var y = ev.originalEvent.touches[0].pageY || 0;
    self.touchgrab(x, y);
    ev.preventDefault();
    ev.stopPropagation();
  });
  if (construct) construct.apply(this);
  this.id = INSTANCES.length;
  INSTANCES.push(this);
  return this;
}

Popup.fetch = function(resource, title, icon, thin, loadedFunc) {
  return new Popup(title, icon, function() {
    var self = this;
    
    this.content.html('<div class="loader"><i class="fa fa-pulse fa-spinner" /></div>');
    this.thin = thin;
    if (thin) this.container.addClass('thin');
    
    ajax(resource, function(xml, type, ev) {
      self.content.html(ev.responseText);
      self.content.find('.cancel').on('click', function() {
        self.close();
      });
      self.center();
      if (loadedFunc && typeof window[loadedFunc] === 'function') {
        window[loadedFunc](self.content);
      }
    }, 1);
    this.show();
  });
};

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
    this.x = (win.width() - this.container.width()) / 2 + win.scrollLeft();
    this.y = (win.height() - this.container.height()) / 2 + win.scrollTop();
    this.move(this.x, this.y);
  },
  bob: function(reverse, callback) {
    if (reverse) {
      this.container.css('transition', 'transform 0.5s ease, opacity 0.5s ease');
      this.container.css({
        opacity: 0, transform: 'translate(0,30px)'
      });
    } else {
      this.container.css('transition', 'transform 0.5s ease, opacity 0.5s ease');
      timeoutOn(this, function() {
        this.container.css({
          opacity: 1, transform: 'translate(0,0)'
        });
      }, 1);
    }
    timeoutOn(this, function() {
      if (callback) callback(this);
    }, 500);
  },
  handleShortcut: function(e) {
    if (e.which == Key.ENTER) {
      this.dom.find('.confirm').click();
      this.close();
      e.preventDefault();
      e.stopPropagation();
    } else if (e.which == Key.ESC) {
      this.close();
      e.preventDefault();
      e.stopPropagation();
    }
  },
  show: function() {
    $('.popup-container.focus').removeClass('focus');
    this.container.addClass('focus');
    this.container.css({
      opacity: 0, transform: 'translate(0,30px)'
    });
    this.container.css('display', '');
    $('body').append(this.container);
    if (this.thin || this.x <= 0 || this.y <= 0) {
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
        INSTANCES.splice(this.id, 1);
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
    var self = this;
    var offX = x - this.container.offset().left;
    var offY = y - this.container.offset().top;
    this.dragging = function(ev) {
      self.move(ev.pageX - offX, ev.pageY - offY);
    };
    this.focus();
    $(document).on('mousemove', this.dragging);
    $(document).one('mouseup', function() {
      self.release();
    });
  },
  touchgrab: function(x, y) {
    var self = this;
    var offX = x - this.container.offset().left;
    var offY = y - this.container.offset().top;
    this.dragging = function(ev) {
      var x = ev.originalEvent.touches[0].pageX || 0;
      var y = ev.originalEvent.touches[0].pageY || 0;
      self.move(x - offX, y - offY);
    };
    this.focus();
    $(document).on('touchmove', this.dragging);
    $(document).one('touchend', function() {
      self.release();
    });
  },
  release: function() {
    if (this.dragging) {
      $(document).off('mousemove touchmove', this.dragging);
      this.dragging = null;
    }
  },
  resize: function() {
    if (this.thin) {
      this.center();
    } else {
      this.move(this.x, this.y);
    }
  },
  move: function(x, y) {
    var scrollX = win.scrollLeft();
    var scrollY = win.scrollTop();
    if (this.fixed) {
      x -= scrollX;
      y -= scrollY;
      scrollX = 0;
      scrollY = 0;
    }
    if (x > win.width() - this.container.width() + scrollX) x = win.width() - this.container.width() + scrollX;
    if (y > win.height() - this.container.height() + scrollY) y = win.height() - this.container.height() + scrollY;
    if (y < 0) y = 0;
    if (x < 0) x = 0;
    this.container.css({top: this.y = y, left: this.x = x});
  },
  setFixed: function() {
    this.fixed = true;
    this.container.css('position', 'fixed');
    return this;
  },
  setWidth: function(width) {
    this.content.css('max-width', width);
    return this;
  }
};

function error(message) {
  new Popup('Error', 'warning', function() {
    var self = this;
    var ok = $('<button class="right button-fw">Ok</button>');
    ok.on('click', function() {
      self.close();
    });
    this.content.append('<div class="message_content">' + message + '</div><div class="foot"></div>');
    this.content.find('.foot').append(ok);
    this.setWidth(400);
    this.show();
  });
};

export { Popup, error };
