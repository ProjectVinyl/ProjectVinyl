/**
 * Windows
 */
import { jSlim } from '../utils/jslim';
import { Key } from '../utils/misc';
import { initDraggable, move } from './draggable';

var openedWindows = [];

function createPopupContent(params) {
  var dom = document.createElement('DIV');
  dom.setAttribute('class', 'popup-container focus transitional hidden');
  dom.innerHTML = '\
  <div class="popup">\
    <h1 class="popup-header">\
      <i class="fa ' + params.icon + '"></i>\
      ' + params.title + '\
      <a class="close" data-resolve="false"></a>\
    </h1>\
    <div class="content">\
      <div class="message_content">' + params.content + '</div>\
      <div class="foot center hidden"></div>\
    </div>\
  </div>';
  return dom;
}

function PopupWindow(dom) {
  this.dom = dom;
  this.dom.windowObj = this;
  this.content = this.dom.querySelector('.content');
  this.foot = this.content.querySelector('.foot');
  this.id = -1;
}
PopupWindow.prototype = {
  show: function() {
    if (this.id < 0) {
      this.id = openedWindows.length;
      openedWindows.push(this);
    }
    document.querySelector('.fades').insertAdjacentElement('beforebegin', this.dom);
    requestAnimationFrame(() => {
      this.focus();
      centerWindow(this);
    });
  },
  close: function() {
    openedWindows.splice(this.id, 1);
    this.id = -1;
    if (this.dom.classList.contains('focus'))  {
      if (openedWindows.length) {
        openedWindows[openedWindows.length - 1].focus();
      }
    }
    
    this.dom.classList.add('hidden');
    setTimeout(() => {
      this.dom.parentNode.removeChild(this.dom);
    }, 500);
  },
  focus: function() {
    jSlim.all(document, '.popup-container.focus', function(a) {
      a.classList.remove('focus');
    });
    this.dom.classList.remove('hidden');
    this.dom.classList.add('focus');
  },
  setContent: function(content) {
    this.content.innerHTML = content;
  },
  setFooter: function(content) {
    this.foot.classList.remove('hidden');
    this.foot.innerHTML = content;
  },
  setOnAccept: function(func) {
    this.accept = func;
  }
}

function resolveWith(win, result) {
  win.close();
  if (result && win.accept) win.accept();
}

function handleEvents(win) {
  jSlim.on(win.dom, 'click', '[data-resolve]', function(e) {
    if (e.target.matches('[data-resolve]')) {
      resolveWith(win, e.target.dataset.resolve === 'true');
    }
  });
  initDraggable(win.dom, 'h1.popup-header');
}

jSlim.ready(function() {
  document.addEventListener('keydown', function(e) {
    var activeWindow = document.querySelector('.popup-container.focus');
    if (!activeWindow) return;
    if (e.which === Key.ESC) resolveWith(activeWindow.windowObj, false);
    if (e.which === Key.ENTER) {
      var accept = activeWindow.querySelector('.confirm');
      if (accept) {
        accept.dispatchEvent(new MouseEvent('click'));
      } else {
        resolveWith(activeWindow.windowObj, true);
      }
      e.preventDefault(); // hitting enter triggers the link again, let's stop that.
    }
  });
  document.querySelector('.fades').addEventListener('click', function() {
    var activeWindow = document.querySelector('.popup-container.focus');
    if (activeWindow) {
      resolveWith(activeWindow.windowObj, false);
    }
  });
});

export function createWindow(params) {
  var win = new PopupWindow(createPopupContent(params));
  handleEvents(win);
  win.show();
  return win;
}

export function centerWindow(win) {
  var x = (document.body.offsetWidth - win.dom.offsetWidth) / 2 + document.scrollingElement.scrollLeft,
      y = (document.body.offsetHeight - win.dom.offsetHeight) / 2 + document.scrollingElement.scrollTop;
  move(win.dom, x, y);
}