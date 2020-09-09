/**
 * Drag targets.
 */
import { delegateAll } from '../../jslim/events';

function enterDrag() {
  this.classList.add('drag');
}

function leaveDrag() {
  this.classList.remove('drag');
}

delegateAll(document, '.drag-target', {
  dragover: enterDrag, dragenter: enterDrag,
  dragleave: leaveDrag, drop: leaveDrag
});
