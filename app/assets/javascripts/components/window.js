/**
 * Windows
 */
import { jSlim } from '../utils/jslim';
import { Key } from '../utils/misc';

var INSTANCES = [];
var activeWindow = null;

function createPopupContent(params) {
  return '\
  <div class="popup">\
    <h1 class="popup-header">\
      <i class="fa ' + params.icon + '"></i>\
      ' + params.title + '\
      <a class="close" data-resolve="false"></a>\
    </h1>\
    <div class="content">\
      <div class="message_content">' + params.content + '</div>\
      <div class="foot center">' + params.foot + '</div>\
    </div>\
  </div>';
}

export function closeWindow(win) {
  if (activeWindow == win) activeWindow = null;
  if (!INSTANCES.length) {
    document.removeEventListener('keydown', closeMe);
  }
  bob(win, true, function() {
    document.body.removeChild(win.overlay);
    INSTANCES.splice(win.id, 1);
  });
  if (win.fade) {
    win.fade.style.opacity = 0;
    setTimeout(function() {
      win.fade.parentNode.removeChild(win.fade);
    }, 500);
  }
}

export function createWindow(params) {
  var dom = document.createElement('DIV');
  dom.setAttribute('class', 'popup-container focus');
  dom.setAttribute('style', 'display:none;opacity:0;');
  dom.innerHTML = createPopupContent(params);
  
  activeWindow = {
    id: INSTANCES.length,
    overlay: dom,
    dom: dom.querySelector('.popup'),
    x: -1,
    y: -1
  };
  INSTANCES.push(activeWindow);
  showWindow(activeWindow);
  return activeWindow;
}

function showWindow(win) {
  win.overlay.style.opacity = 1;
  win.overlay.style.transform = 'translate(0,30px)';
  win.overlay.style.display = '';
  document.body.appendChild(win.overlay);
  handleEvents(win);
  if (win.thin || win.x <= 0 || win.y <= 0) {
    centerWindow(win);
  }
  win.fade = document.createElement('DIV');
  win.fade.style.opacity = 0;
  document.querySelector('.fades').appendChild(win.fade);
  setTimeout(function() {
    win.fade.style.opacity = 1;
  }, 1);
  bob(win);
}

function bob(win, reverse, callback) {
  win.overlay.style.transition = 'transform 0.5s ease, opacity 0.5s ease';
  if (reverse) {
    win.overlay.style.opacity = 0;
    win.overlay.style.transform = 'translate(0,30px)';
  } else {
    setTimeout(function() {
      win.overlay.style.opacity = 1;
      win.overlay.style.transform = 'translate(0,0)';
    }, 1);
  }
  if (callback) setInterval(callback, 500);
}

function resolveWith(win, result) {
  closeWindow(win);
  if (val && win.accept) win.accept();
}

function closeMe(e) {
  if (activeWindow) {
    if (e.which === Key.ESC) resolveWith(activeWindow, false);
    if (e.which === Key.ENTER) resolveWith(activeWindow, true);
  }
}

function doGrab(sender, x, y, func, move, end) {
  var off = jSlim.offset(sender.overlay);
  var offX = x - off.left;
  var offY = y - off.top;
  sender.dragging = function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    ev = func(ev);
    moveWindow(sender, ev.x - offX, ev.y - offY);
  };
  sender.dragging.ev = move;
  document.addEventListener(move, sender.dragging);
  document.addEventListener(end, function() {
    releaseWindow(sender);
  });
}

function releaseWindow(win) {
  if (win.dragging) {
    document.removeEventListener(win.dragging.ev, win.dragging);
    win.dragging = null;
  }
}

export function centerWindow(win) {
  win.x = (document.body.offsetWidth - win.overlay.offsetWidth) / 2 + document.scrollingElement.scrollLeft;
  win.y = (document.body.offsetHeight - win.overlay.offsetHeight) / 2 + document.scrollingElement.scrollTop;
  moveWindow(win, win.x, win.y);
}

function moveWindow(win, x, y) {
  var scrollX = document.scrollingElement.scrollLeft;
  var scrollY = document.scrollingElement.scrollTop;
  if (win.fixed) {
    x -= scrollX;
    y -= scrollY;
    scrollX = 0;
    scrollY = 0;
  }
  if (x > document.body.offsetWidth - win.overlay.offsetWidth + scrollX) x = document.body.offsetWidth - win.overlay.offsetWidth + scrollX;
  if (y > document.body.offsetheight - win.overlay.offsetHeight + scrollY) y = document.body.offsetheight - win.overlay.offsetHeight + scrollY;
  if (y < 0) y = 0;
  if (x < 0) x = 0;
  win.overlay.style.top = (win.y = y) + 'px';
  win.overlay.style.left = (win.x = x) + 'px';
}

export function handleEvents(win) {
  jSlim.on(win.dom, 'click', '[data-resolve]', function(e) {
    if (e.target.matches('[data-resolve]')) {
      resolveWith(win, e.target.dataset.resolve === 'true');
    }
    activeWindow = win;
  });
  jSlim.on(win.dom, 'mousedown', 'h1.popup-header', function(e) {
    doGrab(win, e.pageX, e.pageY, function(ev) {
      return {x: ev.pageX, y: ev.pageY};
    }, 'mousemove', 'mouseup');
    e.preventDefault(); // Prevents text selections
  });
  jSlim.on(win.dom, 'touchstart', 'h1.popup-header', function(e) {
    var x = ev.originalEvent.touches[0].pageX || 0;
    var y = ev.originalEvent.touches[0].pageY || 0;
    doGrab(win, x, y, function(ev) {
      return {x: ev.originalEvent.touches[0].pageX || 0, y: ev.originalEvent.touches[0].pageY};
    }, 'touchmove', 'touchend');
    e.preventDefault(); // et tu.
  });
  document.addEventListener('keydown', closeMe);
}