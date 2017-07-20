function getHandlers(el, event, bubble) {
  var handlers = el.handlers || (el.handlers = {});
  handlers = handlers[event] || (handlers[event] = []);
  if (!handlers.length) {
    el.addEventListener(event, function(e) {
      triggerEvents(this, event, handlers, e);
    }, bubble);
  }
  return handlers;
}

function triggerEvents(sender, event, eventHandlers, e) {
  eventHandlers.forEach(function(handler) {
    if (!handler.selector) {
      return handler.callback.call(sender, e);
    }
    var target = e.target && e.target.closest && e.target.closest(handler.selector);
    if (target) {
      if ((event == 'mouseout' || event == 'mouseover') && target.contains(e.relatedTarget)) return;
      handler.callback.call(target, e);
    }
  });
}

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
  bind: function(el, event, func, bubble) {
    getHandlers(el, event, bubble).push({
      callback: func
    });
  },
  on: function(el, event, selector, func, bubble) {
    getHandlers(el, event, bubble).push({
      selector: selector,
      callback: func
    });
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
    jSlim.bind(document, 'DOMContentLoaded', func);
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
