import { jSlim } from '../utils/jslim';

function grab(ev, sender, x, y, func, moveev, end) {
  ev.preventDefault(); // prevent text selection
  var off = jSlim.offset(sender);
  
  document.addEventListener(moveev, dragging);
  document.addEventListener(end, () => {
    document.removeEventListener(moveev, dragging);
  });
  
  function dragging(e) {
    e.preventDefault(); // et tu.
    e = func(e);
    move(sender, e.x - x + off.left, e.y - y + off.top);
  }
}

export function move(sender, x, y) {
  var scrollX = document.scrollingElement.scrollLeft;
  var scrollY = document.scrollingElement.scrollTop;
  if (x > document.body.offsetWidth - sender.offsetWidth + scrollX) x = document.body.offsetWidth - sender.offsetWidth + scrollX;
  if (y > document.body.offsetheight - sender.offsetHeight + scrollY) y = document.body.offsetheight - sender.offsetHeight + scrollY;
  if (y < 0) y = 0;
  if (x < 0) x = 0;
  sender.style.top = y + 'px';
  sender.style.left = x + 'px';
}

export function initDraggable(sender) {
  jSlim.on(sender, 'mousedown', 'h1.popup-header', function(e) {
    grab(e, sender, e.pageX, e.pageY, function(ev) {
      return {
        x: ev.pageX,
        y: ev.pageY
      };
    }, 'mousemove', 'mouseup');
  });
  jSlim.on(sender, 'touchstart', 'h1.popup-header', function(e) {
    var x = ev.originalEvent.touches[0].pageX || 0;
    var y = ev.originalEvent.touches[0].pageY || 0;
    grab(e, sender, x, y, function(ev) {
      return {
        x: ev.originalEvent.touches[0].pageX || 0,
        y: ev.originalEvent.touches[0].pageY
      };
    }, 'touchmove', 'touchend');
  });
}