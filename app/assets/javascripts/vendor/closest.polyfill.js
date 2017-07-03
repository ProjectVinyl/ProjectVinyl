// element-closest | CC0-1.0 | github.com/jonathantneal/closest

if (typeof Element.prototype.matches !== 'function') {
  Element.prototype.matches = Element.prototype.msMatchesSelector || Element.prototype.mozMatchesSelector || Element.prototype.webkitMatchesSelector || function matches(selector) {
    var elements = (this.document || this.ownerDocument).querySelectorAll(selector);
    var index = 0;
    while (elements[index]) {
      if (elements[index++] === this) {
        return true;
      }
    }
    return false;
  };
}

if (typeof Element.prototype.closest !== 'function') {
  Element.prototype.closest = function closest(selector) {
    var element = this;
    while (element && element.nodeType === 1) {
      if (element.matches(selector)) {
        return element;
      }
      element = element.parentNode;
    }
    return null;
  };
}
