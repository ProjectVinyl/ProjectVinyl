import { ajax } from '../utils/ajax';
import { Key } from '../utils/misc';
import { jSlim } from '../utils/jslim';

var INSTANCES = [];

window.addEventListener('resize', function() {
  INSTANCES.forEach(function(i) {
    i.resize();
  });
});
window.addEventListener('keydown', function(e) {
  if (INSTANCES.length && !document.querySelector('input:focus, textarea:focus, button:focus, .button.focus')) {
    var c = document.querySelector('.popup-container.focus');
    if (c) c.instance.handleShortcut(e);
  }
});

function timeoutOn(target, func, time) {
  return setTimeout(func.bind(target), time);
}

function unfocusPopups() {
  jSlim.all('.popup-container.focus', function(a) {
    a.classList.remove('focus');
  });
}

function doGrab(sender, x, y, func, move, end) {
  var off = jSlim.offset(sender.container);
  var offX = x - off.left;
  var offY = y - off.top;
  sender.focus();
  sender.dragging = function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    ev = func(ev);
    sender.move(ev.x - offX, ev.y - offY);
  };
  sender.dragging.ev = move;
  document.addEventListener(move, sender.dragging);
  document.addEventListener(end, function() {
    sender.release();
  });
}

function Popup(title, icon, construct) {
  var self = this;
  
  this.container = document.createElement('DIV');
  this.container.classList.add('popup-container');
  this.container.instance = this;
  this.container.innerHTML = '<div class="popup"><h1 class="popup-header"><i class="fa"></i>' + title + '<a class="close"></a></h1><div class="content"></div></div>';
  this.dom = this.container.firstChild;
  this.content = this.dom.lastChild;
  this.fixed = false;
  this.x = this.y = -1;
  
  if (typeof icon === 'string') {
    this.dom.querySelector('.fa').classList.add('fa-' + icon);
  }
  if (typeof icon === 'function') construct = icon;
  
  this.container.addEventListener('click', focusFunc);
  this.container.addEventListener('mousedown', focusFunc);
  this.container.addEventListener('mouseup', focusFunc);
  
  function focusFunc() {
    self.focus();
  }
  
  jSlim.on(this.container, 'click', '.close, .cancel', closeFunc);
  jSlim.on(this.container, 'click', '.confirm', function() {
    if (self.confirm) self.confirm();
    self.close();
  });
  jSlim.on(this.container, 'touchend', '.close', closeFunc);
  function closeFunc() {
    self.close();
  }
  
  jSlim.on(this.container, 'mousedown', 'h1.popup-header', function(ev) {
    self.grab(ev.pageX, ev.pageY);
    ev.preventDefault();
    ev.stopPropagation();
  });
  jSlim.on(this.container, 'touchstart', 'h1.popup-header', function(ev) {
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

Popup.fetch = function(resource, title, icon, thin, targetEl) {
  return new Popup(title, icon, function() {
    var self = this;
    
    this.content.innerHTML = '<div class="loader"><i class="fa fa-pulse fa-spinner"></i></div>';
    this.thin = thin;
    if (thin) this.container.classList.add('thin');
    ajax.get(resource).text(function(text) {
      self.content.innerHTML = text;
      self.center();
      if (targetEl) {
        targetEl.dispatchEvent(new CustomEvent('loaded', {
          detail: { content: self.content },
          bubbles: true
        }));
      }
    });
    this.show();
  });
};

Popup.prototype = {
  setPersistent: function() {
    this.persistent = true;
  },
  focus: function() {
    if (!this.container.classList.contains('focus')) {
      this.container.parentNode.appendChild(this.container);
      this.fade.parentNode.appendChild(this.fade);
      unfocusPopups();
      this.container.classList.add('focus');
    }
  },
  center: function() {
    this.x = (document.body.offsetWidth - this.container.offsetWidth) / 2 + document.scrollingElement.scrollLeft;
    this.y = (document.body.offsetHeight - this.container.offsetHeight) / 2 + document.scrollingElement.scrollTop;
    this.move(this.x, this.y);
  },
  bob: function(reverse, callback) {
    this.container.style.transition = 'transform 0.5s ease, opacity 0.5s ease';
    if (reverse) {
      this.container.style.opacity = 0;
      this.container.style.transform = 'translate(0,30px)';
    } else {
      timeoutOn(this, function() {
        this.container.style.opacity = 1;
        this.container.style.transform = 'translate(0,0)';
      }, 1);
    }
    timeoutOn(this, function() {
      if (callback) callback(this);
    }, 500);
  },
  handleShortcut: function(e) {
    if (e.which == Key.ENTER) {
      this.dom.querySelector('.confirm').dispatchEvent(new Event('click'));
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
    unfocusPopups();
    this.container.classList.add('focus');
    this.container.style.opacity = 1;
    this.container.style.transform = 'translate(0,30px)';
    this.container.style.display = '';
    document.body.appendChild(this.container);
    if (this.thin || this.x <= 0 || this.y <= 0) {
      this.center();
    }
    this.fade = document.createElement('DIV');
    this.fade.style.opacity = 0;
    document.querySelector('.fades').appendChild(this.fade);
    timeoutOn(this, function() {
      this.fade.style.opacity = 1;
    }, 1);
    this.bob();
  },
  close: function() {
    this.bob(1, function(me) {
      if (!me.persistent) {
        me.container.remove();
        INSTANCES.splice(this.id, 1);
      } else {
        me.container.style.display = 'none';
      }
    });
    if (this.fade) {
      this.fade.style.opacity = 0;
      timeoutOn(this, function() {
        this.fade.parentNode.removeChild(this.fade);
      }, 500);
    }
  },
  setId: function(id) {
    this.container.setAttribute('id', id);
    return this;
  },
  grab: function(x, y) {
    doGrab(this, x, y, function(ev) {
      return {x: ev.pageX, y: ev.pageY};
    }, 'mousemove', 'mouseup');
  },
  touchgrab: function(x, y) {
    doGrab(this, x, y, function(ev) {
      return {x: ev.originalEvent.touches[0].pageX || 0, y: ev.originalEvent.touches[0].pageY};
    }, 'touchmove', 'touchend');
  },
  release: function() {
    if (this.dragging) {
      document.removeEventListener(this.dragging.ev, this.dragging);
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
    var scrollX = document.scrollingElement.scrollLeft;
    var scrollY = document.scrollingElement.scrollTop;
    if (this.fixed) {
      x -= scrollX;
      y -= scrollY;
      scrollX = 0;
      scrollY = 0;
    }
    if (x > document.body.offsetWidth - this.container.offsetWidth + scrollX) x = document.body.offsetWidth - this.container.offsetWidth + scrollX;
    if (y > document.body.offsetheight - this.container.offsetHeight + scrollY) y = document.body.offsetheight - this.container.offsetHeight + scrollY;
    if (y < 0) y = 0;
    if (x < 0) x = 0;
    this.container.style.top = (this.y = y) + 'px';
    this.container.style.left = (this.x = x) + 'px';
  },
  setFixed: function() {
    this.fixed = true;
    this.container.style.position = 'fixed';
    return this;
  },
  setWidth: function(width) {
    this.content.style.maxWidth = width;
    return this;
  }
};

function error(message) {
  new Popup('Error', 'warning', function() {
    var msg = document.createElement('DIV');
    this.content.appendChild(msg);
    msg.innerText = message;
    msg.classList.add('message_content');
    msg = document.createElement('DIV');
    msg.classList.add('foot');
    msg.innerHTML = '<button type="button" class="button-fw confirm right">Ok</button>';
    this.content.appendChild(msg);
    this.setWidth(400);
    this.show();
  });
}
// Debugging purposes
window.error = error;

export { Popup, error };
