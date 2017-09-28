
const div = document.createElement('DIV');
function pull(input, push) {
  div.innerHTML = input;
  input = push();
  div.innerHTML = '';
  return input;
}

export function nodeFromHTML(html) {
  return pull(html, () => div.firstElementChild);
}

export function decodeEntities(string) {
  pull(string, () => div.innerText);
}

export function offset(element) {
  if (!element || !element.getClientRects().length) {
    return { top: 0, left: 0 };
  }
  const rect = element.getBoundingClientRect();
  let doc = element.ownerDocument || document;
  const win = doc.defaultView || window;
  doc = doc.documentElement;
  
  return {
    top: rect.top + win.pageYOffset - doc.clientTop,
    left: rect.left + win.pageXOffset - doc.clientLeft
  };
}

export function subtractOffsets(offOne, offTwo) {
  return {top: offOne.top - offTwo.top, left: offOne.left - offTwo.left};
}

export function each(arrLike, func, thisArg) {
  Array.prototype.forEach.call(arrLike, func, thisArg);
}

export function all(el, selector, func, thisArg) {
  if (typeof el == 'string') return all(document, el, selector, func);
  return each((el || document).querySelectorAll(selector), func, thisArg);
}
