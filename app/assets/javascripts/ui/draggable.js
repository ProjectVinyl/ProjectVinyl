import { addDelegatedEvent , bindEvent, dispatchEvent } from '../jslim/events';
import { clamp } from '../utils/math';
import { captureClicks } from '../utils/event_capturing';

export function move(sender, x, y) {
  sender.preferredPos = setPos(sender, x, y);
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

  const maxX  = 1 - (sender.clientWidth / parent.offsetWidth);
  const maxY = 1 - (sender.clientHeight / parent.offsetHeight);

  // Clamp to valid region on the page
  x = clamp(x / parent.offsetWidth, 0, maxX);
  y = clamp(y / parent.offsetHeight, 0, maxY);

  sender.style.top = `${100 * y}%`;
  sender.style.left = `${100 * x}%`;

  return {x, y};
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
    dispatchEvent('draggable:release', {}, sender);
  });

  dispatchEvent('draggable:grab', {}, sender);
}

bindEvent(window, 'resize', () => {
  document.querySelectorAll('.ui-draggable').forEach(el => {
    if (el.preferredPos) {
      el.style.left = el.style.top = 0;
      // try to get back to where the user left it (or as close as possible)
      const parent = getRelativeParent(el);
      setPos(el,
        el.preferredPos.x * parent.offsetWidth,
        el.preferredPos.y * parent.offsetHeight
      );
    }
  });
});

addDelegatedEvent(window, 'mousedown', '.ui-draggable .drag-handle', grabDraggable);
