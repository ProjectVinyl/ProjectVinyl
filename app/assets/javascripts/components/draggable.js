import { addDelegatedEvent, ready , bindEvent } from '../jslim/events';
import { offset } from '../jslim/dom';
import { clamp } from '../utils/math';

export function move(sender, x, y) {
  setPos(sender, x, y);
  sender.prefX = x;
  sender.prefY = y;
}

function setPos(sender, x, y) {
  const maxX  = document.body.offsetWidth - sender.clientWidth;
  const maxY = document.body.offsetHeight - sender.clientHeight;
  // Clamp to valid region on the page
  sender.style.top = `${clamp(y, 0, maxY)}px`;
  sender.style.left = `${clamp(x, 0, maxX)}px`;
}

export function initDraggable(sender, target) {
  addDelegatedEvent(sender, 'mousedown', target, start => {
    start.preventDefault(); // prevent text selection
    
    const off  = offset(sender);
    const offX = off.left - start.pageX;
    const offY = off.top - start.pageY;
    
    function dragging(change) {
      change.preventDefault(); // ditto
      move(sender, change.clientX + offX, change.clientY + offY);
    }
    
    document.addEventListener('mousemove', dragging);
    document.addEventListener('mouseup', () => {
      document.removeEventListener('mousemove', dragging);
    });
  });
}

bindEvent(window, 'resize', () => {
  document.querySelectorAll('.ui-draggable').forEach(el => {
    el.style.top = el.style.left = '0px'; // reposition element for size calculations
    setPos(el, el.prefX, el.prefY); // try to get back to where the user left it (or as close as possible)
  });
});
