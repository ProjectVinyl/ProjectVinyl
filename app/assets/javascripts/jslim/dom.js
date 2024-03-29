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
  return pull(string, () => div.innerText);
}

export function offset(element) {
  return element.getBoundingClientRect();
  // TODO: why do we need any of this?
  /*if (!element || !element.getClientRects().length) {
    return { top: 0, left: 0 };
  }
  const rect = element.getBoundingClientRect();
  let doc = element.ownerDocument || document;
  const win = doc.defaultView || window;
  doc = doc.documentElement;

  return {
    top: rect.top + win.pageYOffset - doc.clientTop,
    left: rect.left + win.pageXOffset - doc.clientLeft
  };*/
}

export function subtractOffsets(offOne, offTwo) {
  return {
    top: offOne.top - offTwo.top,
    left: offOne.left - offTwo.left
  };
}
