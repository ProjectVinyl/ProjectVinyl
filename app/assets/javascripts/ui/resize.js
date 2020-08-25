import { ready, bindEvent } from '../jslim/events';
import { all } from '../jslim/dom';
import { linearInterpolate, clamp } from '../utils/math';

function sizeFont(el, targetWidth) {
  // Remove the previously calculated size to prevent it from spoiling the results
  el.style.fontSize = '';

  let computed = getComputedStyle(el);
  const currentFontSize = parseFloat(computed.fontSize);
  
  const div = document.createElement('div');
  div.setAttribute('style', 'position:fixed;top:0;left:0;white-space:nowrap');
  div.style.fontFamily = computed.fontFamily;
  div.style.fontWeight = computed.fontWeight;
  div.style.fontSizeAdjust = computed.fontSizeAdjust;
  div.style.paddingLeft = computed.paddingLeft;
  div.style.paddingRight = computed.paddingRight;
  div.textContent = el.textContent;
  document.body.appendChild(div);
  
  // Using 2 style recalculations, we can determine the slope of the linear
  // equation defining the font-size for a given element width:
  //   independent X = width
  //   dependent   Y = font size
  
  computed = getComputedStyle(div);
  const x1 = div.clientWidth, y1 = parseFloat(computed.fontSize);
  
  div.style.fontSize = `${parseFloat(computed.fontSize) + 1}px`;
  computed = getComputedStyle(div);
  const x2 = div.clientWidth, y2 = parseFloat(computed.fontSize);
  
  let newSize = linearInterpolate({x1, y1}, {x2, y2}, targetWidth);
  
  // clamped minimum/maximum font sizes
  newSize = clamp(newSize, 5, currentFontSize);

  el.style.fontSize = `${newSize}px`;
  document.body.removeChild(div);
}

export function resizeFont(el) {
  const holder = el.closest('.resize-holder');
  const computed = getComputedStyle(holder);
  const targetWidth = holder.offsetWidth - (parseFloat(computed.paddingLeft) + parseFloat(computed.paddingRight));
  
  sizeFont(el, targetWidth);
}

function fixFonts() {
  all('h1.resize-target', resizeFont);
}

bindEvent(window, 'resize', fixFonts);
bindEvent(window, 'load', fixFonts);
ready(fixFonts);
