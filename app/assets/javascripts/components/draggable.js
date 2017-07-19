import { jSlim } from '../utils/jslim';

export function move(sender, x, y) {
  setPos(sender, x, y);
  sender.prefX = x;
  sender.prefY = y;
}

function setPos(sender, x, y) {
  var maxX  = document.body.offsetWidth - sender.clientWidth;
  var maxY = document.body.offsetHeight - sender.clientHeight;
  // Clamp to valid region on the page
  if (x > maxX)  x = maxX;
  if (y > maxY) y = maxY;
  if (x < 0) x = 0;
  if (y < 0) y = 0;
  
  sender.style.top = y + 'px';
  sender.style.left = x + 'px';
}

export function initDraggable(sender, target) {
  jSlim.on(sender, 'mousedown', target, function(start) {
    start.preventDefault(); // prevent text selection
    
    const off  = jSlim.offset(sender);
    const offX = off.left - start.pageX;
    const offY = off.top - start.pageY;
    
    function dragging(change) {
      change.preventDefault(); // ditto
      move(sender, change.clientX + offX, change.clientY + offY);
    }
    
    document.addEventListener('mousemove', dragging);
    document.addEventListener('mouseup', function() {
      document.removeEventListener('mousemove', dragging);
    });
  });
}

jSlim.ready(function() {
  window.addEventListener('resize', function() {
    jSlim.all('.ui-draggable', function(el) {
      el.style.top = el.style.left = '0px'; // reposition element for size calculations
      setPos(el, el.prefX, el.prefY); // try to get back to where the user left it (or as close as possible)
    });
  });
});