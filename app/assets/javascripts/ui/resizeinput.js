/**
 * Automatically-resizing <input>s.
 */

import { jSlim } from '../utils/jslim';

jSlim.on(document, 'keyup', 'input.js-auto-resize', function() {
  const input = this;
  const width = input.clientWidth;

  input.style.width = '0px';
  input.style.marginLeft = `${width}px`
  input.style.width = `${input.scrollWidth + 20}px`;
  input.style.marginLeft = '';
});
