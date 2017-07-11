/**
 * Drag targets.
 */

import { jSlim } from '../utils/jslim';

function enterDrag() {
  this.classList.add('drag');
}

function leaveDrag() {
  this.classList.remove('drag');
}

jSlim.on(document, 'dragover', '.drag-target', enterDrag);
jSlim.on(document, 'dragenter', '.drag-target', enterDrag);
jSlim.on(document, 'dragleave', '.drag-target', leaveDrag);
jSlim.on(document, 'drop', '.drag-target', leaveDrag);
