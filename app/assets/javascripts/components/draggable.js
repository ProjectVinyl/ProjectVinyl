import { jSlim } from '../utils/jslim';

export function move(sender, x, y) {
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

export function initDraggable(sender) {
  jSlim.on(sender, 'mousedown', 'h1.popup-header', function(start) {
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
