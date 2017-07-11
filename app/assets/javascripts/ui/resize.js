import { jSlim } from '../utils/jslim';
import { linearInterpolate } from '../utils/math';

function sizeFont(el, targetWidth) {
  const div = document.createElement('div');
  let computed = getComputedStyle(el);
  
  div.setAttribute('style', 'position:fixed;top:0;left:0;white-space:nowrap;background:#fff');
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
  
  div.style.fontSize = (parseFloat(computed.fontSize) + 1) + 'px';
  computed = getComputedStyle(div);
  const x2 = div.clientWidth, y2 = parseFloat(computed.fontSize);

  let newSize = linearInterpolate({x1, y1}, {x2, y2}, targetWidth);
  
  // clamped minimum/maximum font sizes
  if (newSize < 5) newSize = 5;
  if (newSize > 16.25) newSize = 16.25;
  
  el.style.fontSize = newSize + 'px';
  document.body.removeChild(div);
}

function resizeFont(el) {
  const holder = el.closest('.resize-holder');
  const computed = getComputedStyle(holder);
  const targetWidth = parseFloat(computed.width) - (parseFloat(computed.paddingLeft) + parseFloat(computed.paddingRight));
  
  sizeFont(el, targetWidth);
}

function fixFonts() {
  jSlim.all('h1.resize-target', resizeFont);
}

window.addEventListener('resize', fixFonts);
jSlim.ready(fixFonts);

export { resizeFont };
