const jSlim = {
  dom: (function() {
    var div = document.createElement('DIV');
    function pull(input, push) {
      div.innerHTML = input;
      input = push();
      div.innerHTML = '';
      return input;
    }
    return {
      load: function(html) {
        return pull(html, function() {
          return Array.apply(null, div.children);
        });
      },
      decodeEntities: function(string) {
        return pull(string, function() {
          return div.innerText;
        });
      }
    };
  })(),
  on: function(el, event, selector, func, bubble) {
    var k = function(e) {
      var target = e.target.closest(selector);
      if (target) {
        if ((event == 'mouseout' || event == 'mouseover') && target.contains(e.relatedTarget)) return;
        return func.call(target, e);
      }
    };
    el.addEventListener(event, k, bubble);
    return k;
  },
  each: function(arrLike, func, thisArg) {
    return Array.prototype.forEach.call(arrLike, func, thisArg);
  },
  all: function(el, selector, func, thisArg) {
    if (typeof el == 'string') {
      return jSlim.all(document, el, selector, func);
    }
    return jSlim.each((el || document).querySelectorAll(selector), func, thisArg);
  },
  ready: function(func) {
    if (document.readyState !== 'loading') {
      return func();
    }
    document.addEventListener('DOMContentLoaded', func);
  },
  offset: function(element) {
    if (!element || !element.getClientRects().length) {
      return { top: 0, left: 0 };
    }
    var rect = element.getBoundingClientRect();
    var doc = element.ownerDocument || document;
    var win = doc.defaultView || window;
    doc = doc.documentElement;
    return {
      top: rect.top + win.pageYOffset - doc.clientTop,
      left: rect.left + win.pageXOffset - doc.clientLeft
    };
  }
};

export { jSlim };
