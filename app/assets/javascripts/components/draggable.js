import { jSlim } from '../utils/jslim';

export function move(sender, x, y) {
  var docWidth  = document.documentElement.scrollWidth;
  var docHeight = document.documentElement.scrollHeight;
  // Clamp to valid region on the page
  if (x + sender.clientWidth  > docWidth)  x = docWidth  - sender.clientWidth;
  if (y + sender.clientHeight > docHeight) y = docHeight - sender.clientHeight;
  if (x < 0) x = 0;
  if (y < 0) y = 0;
  
  sender.style.top = y + 'px';
  sender.style.left = x + 'px';
}

export function initDraggable(sender) {
  jSlim.on(sender, 'mousedown', 'h1.popup-header', function(start) {
    start.preventDefault(); // prevent text selection
    
    const off  = jSlim.offset(sender);
    const offX = off.left - start.clientX;
    const offY = off.top  - start.clientY;
    
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
