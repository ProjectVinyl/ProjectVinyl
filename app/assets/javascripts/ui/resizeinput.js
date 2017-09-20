/**
 * Automatically-resizing <input>s.
 */
import { jSlim } from '../utils/jslim';

jSlim.on(document, 'keyup', 'textarea.js-auto-resize', function() {
  const height = this.clientHeight;
  this.style.height = '0px';
  this.style.marginTop = height + 'px';
  this.style.height = (this.scrollHeight + 20) + 'px';
  this.style.marginTop = '';
});

jSlim.on(document, 'keyup', 'input.js-auto-resize', function() {
  const width = this.clientWidth;
  this.style.width = '0px';
  this.style.marginLeft = width + 'px';
  this.style.width = (this.scrollWidth + 20) + 'px';
  this.style.marginLeft = '';
});
