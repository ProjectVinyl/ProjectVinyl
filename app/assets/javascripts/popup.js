const Popup = (function() {
  const INSTANCES = [];
  const win = $(window);

  win.on('resize', () => {
    for (let i = INSTANCES.length; i--;) INSTANCES[i].resize();
  });
  win.on('keydown', e => {
    if (INSTANCES.length > 0) {
      const c = $('.popup-container.focus');
      if (c.length && !$('input::focuse, textarea::focus, button::focus, .button.focus')) c[0].instance.handleShortcut(e);
    }
  });

  function Popup(title, icon, construct) {
    this.container = $('<div class="popup-container"></div>');
    this.container[0].instance = this;
    this.dom = $(`<div class="popup"><h1>${title}<a class="close" /></h1>`);
    this.container.append(this.dom);
    this.content = $('<div class="content" />');
    this.fixed = false;
    this.x = this.y = -1;
    this.dom.append(this.content);
    if (typeof icon === 'string') {
      this.dom.find('h1').prepend(`<i class="fa fa-${icon}" />`);
    }
    if (typeof icon === 'function') construct = icon;
    const me = this;
    this.container.on('click mousedown mousup', () => {
      me.focus();
    });
    this.dom.find('.close').on('click touchend', () => {
      me.close();
    });
    this.dom.find('h1').on('mousedown', ev => {
      me.grab(ev.pageX, ev.pageY);
      ev.preventDefault();
      ev.stopPropagation();
    });
    this.dom.find('h1').on('touchstart', ev => {
      const x = ev.originalEvent.touches[0].pageX || 0;
      const y = ev.originalEvent.touches[0].pageY || 0;
      me.touchgrab(x, y);
      ev.preventDefault();
      ev.stopPropagation();
    });
    if (construct) construct.apply(this);
    this.id = INSTANCES.length;
    INSTANCES.push(this);
    return this;
  }

  Popup.fetch = function(resource, title, icon, thin, loaded_func) {
    return new Popup(title, icon, function() {
      this.content.html('<div class="loader"><i class="fa fa-pulse fa-spinner" /></div>');
      this.thin = thin;
      if (thin) this.container.addClass('thin');
      const me = this;
      ajax(resource, (xml, type, ev) => {
        me.content.html(ev.responseText);
        me.content.find('.cancel').on('click', () => {
          me.close();
        });
        me.center();
        if (loaded_func && typeof window[loaded_func] === 'function') {
          window[loaded_func](me.content);
        }
      }, 1);
      this.show();
    });
  };

  function domain() {
    return `http${document.domain == 'localhost' ? '' : 's'}://${document.location.hostname}${document.location.port ? `:${document.location.port}` : ''}`;
  }

  function iframe(me, resource) {
    resource = `${domain()}/ajax/${resource}`;
    const frame = document.createElement('iframe');
    frame.style.display = 'none';
    frame.setAttribute('frameborder', '0');
    frame.onload = function() {
      frame.onload = 0;
      me.content.find('.loader').remove();
      frame.style.display = '';
      if (document.location.protocol != 'https:') {
        frame.contentWindow.postMessage('hellow', resource);
        const f = function(e) {
          if ((e.origin || e.originalEvent.origin) == domain()) {
            frame.style.height = e.data;
            me.center();
          }
          window.removeEventListener('mesage', f);
        };
        window.addEventListener('message', f);
      } else {
        frame.style.height = `${frame.contentWindow.document.body.scrollHeight}px`;
        me.center();
        frame.onload = 0;
      }
    };
    frame.src = resource;
    me.content.append(frame);
  }

  Popup.iframe = function(resource, title, icon, thin) {
    return new Popup(title, icon, function() {
      this.content.html('<div class="loader"><i class="fa fa-pulse fa-spinner" /></div>');
      if (thin) this.container.addClass('thin');
      iframe(this, resource);
      this.show();
    });
  };

  Popup.prototype = {
    setPersistent() {
      this.persistent = true;
    },
    focus() {
      if (!this.container.hasClass('focus')) {
        this.container.parent().append(this.container);
        this.fade.parent().append(this.fade);
        $('.popup-container.focus').removeClass('focus');
        this.container.addClass('focus');
      }
    },
    center() {
      this.x = (win.width() - this.container.width()) / 2 + win.scrollLeft();
      this.y = (win.height() - this.container.height()) / 2 + win.scrollTop();
      this.move(this.x, this.y);
    },
    bob(reverse, callback) {
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
    handleShortcut(e) {
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
    show() {
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
    close() {
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
    setId(id) {
      this.container.attr('id', id);
      return this;
    },
    grab(x, y) {
      const me = this;
      const offX = x - this.container.offset().left;
      const offY = y - this.container.offset().top;
      this.dragging = function(ev) {
        me.move(ev.pageX - offX, ev.pageY - offY);
      };
      this.focus();
      $(document).on('mousemove', this.dragging);
      $(document).one('mouseup', () => {
        me.release();
      });
    },
    touchgrab(x, y) {
      const me = this;
      const offX = x - this.container.offset().left;
      const offY = y - this.container.offset().top;
      this.dragging = function(ev) {
        const x = ev.originalEvent.touches[0].pageX || 0;
        const y = ev.originalEvent.touches[0].pageY || 0;
        me.move(x - offX, y - offY);
      };
      this.focus();
      $(document).on('touchmove', this.dragging);
      $(document).one('touchend', () => {
        me.release();
      });
    },
    release() {
      if (this.dragging) {
        $(document).off('mousemove touchmove', this.dragging);
        this.dragging = null;
      }
    },
    resize() {
      if (this.thin) {
        this.center();
      } else {
        this.move(this.x, this.y);
      }
    },
    move(x, y) {
      let scrollX = win.scrollLeft();
      let scrollY = win.scrollTop();
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
    setFixed() {
      this.fixed = true;
      this.container.css('position', 'fixed');
      return this;
    },
    setWidth(width) {
      this.content.css('max-width', width);
      return this;
    }
  };
  return Popup;
}());

function error(message) {
  new Popup('Error', 'warning', function() {
    this.content.append(`<div class="message_content">${message}</div><div class="foot"></div>`);
    const ok = $('<button class="right button-fw">Ok</button>');
    const me = this;
    ok.on('click', () => {
      me.close();
    });
    this.content.find('.foot').append(ok);
    this.setWidth(400);
    this.show();
  });
}
