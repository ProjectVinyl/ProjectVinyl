import { addDelegatedEvent, ready , bindEvent } from '../jslim/events';
import { clamp } from '../utils/math';
import { captureClicks } from '../utils/event_capturing';

export function move(sender, x, y) {
  setPos(sender, x, y);
  sender.prefX = x;
  sender.prefY = y;
}

export function moveToCenter(sender) {
  const parent = getRelativeParent(sender);
  move(sender,
    (parent.offsetWidth - sender.offsetWidth) / 2,
    (parent.offsetHeight - sender.offsetHeight) / 2
  );
}

function getRelativeParent(sender) {
  return sender.closest('.ui-draggable-context') || document.body;
}

function setPos(sender, x, y) {
  const parent = getRelativeParent(sender);
  const maxX  = parent.offsetWidth - sender.clientWidth;
  const maxY = parent.offsetHeight - sender.clientHeight;
  // Clamp to valid region on the page
  sender.style.top = `${clamp(y, 0, maxY)}px`;
  sender.style.left = `${clamp(x, 0, maxX)}px`;
}

function grabDraggable(start, target) {
  const sender = target.closest('.ui-draggable');
  const parent = getRelativeParent(target);

  start.preventDefault(); // prevent text selection

  const parentOff = parent.getBoundingClientRect();

  const off  = sender.getBoundingClientRect();
  const offX = off.left - start.pageX - parentOff.left;
  const offY = off.top - start.pageY - parentOff.top;

  let capturedClicks;

  function dragging(change) {
    change.preventDefault(); // ditto
    move(sender, change.clientX + offX, change.clientY + offY);
    if (!capturedClicks) {
      capturedClicks = captureClicks();
    }
  }

  document.addEventListener('mousemove', dragging);
  document.addEventListener('mouseup', () => {
    document.removeEventListener('mousemove', dragging);
    if (capturedClicks) {
      capturedClicks();
    }
  });
}

bindEvent(window, 'resize', () => {
  document.querySelectorAll('.ui-draggable').forEach(el => {
    el.style.top = el.style.left = '0px'; // reposition element for size calculations
    setPos(el, el.prefX, el.prefY); // try to get back to where the user left it (or as close as possible)
  });
});

addDelegatedEvent(window, 'mousedown', '.ui-draggable .drag-handle', grabDraggable);
