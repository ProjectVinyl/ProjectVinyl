/*
 * Sizing of elements to a determined aspect-ratio.
 */
import { all } from '../../jslim/dom';
import { bindEvent } from '../../jslim/events';

export function resize(obj) {
  applyResize(obj);
  
  setTimeout(() => applyResize(obj), 300);
}

function applyResize(obj) {
  const aspect = obj.dataset.aspect ? parseFloat(obj.dataset.aspect) : (16 / 9);
  obj.style.marginBottom = ''; // 16/9 aspect ratio
  obj.style.height = `${obj.clientWidth / aspect}px`;
}

bindEvent(window, 'resize', () => all('.video', resize));
