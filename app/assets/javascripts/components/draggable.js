import { jSlim } from '../utils/jslim';

export function move(sender, x, y) {
  sender.style.top = y + 'px';
  sender.style.left = x + 'px';
}

export function initDraggable(sender) {
  jSlim.on(sender, 'mousedown', 'h1.popup-header', function(start) {
    start.preventDefault(); // prevent text selection
    
    const off  = jSlim.offset(sender);
    const offX = off.left - start.clientX;
    const offY = off.top  - start.clientY;
    
    const docWidth  = document.documentElement.scrollWidth;
    const docHeight = document.documentElement.scrollHeight;
    
    function dragging(change) {
      change.preventDefault(); // ditto
      
      let x = change.clientX + offX
      let y = change.clientY + offY;
      
      // Clamp to valid region on the page
      if (x + sender.clientWidth  > docWidth)  x = docWidth  - sender.clientWidth;
      if (y + sender.clientHeight > docHeight) y = docHeight - sender.clientHeight;
      if (x < 0) x = 0;
      if (y < 0) y = 0;
      
      move(sender, x, y);
    }
    
    document.addEventListener('mousemove', dragging);
    document.addEventListener('mouseup', function() {
      document.removeEventListener('mousemove', dragging);
    });
  });
}
