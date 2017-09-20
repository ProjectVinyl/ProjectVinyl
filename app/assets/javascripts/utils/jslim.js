function getHandlers(el, event, bubble) {
  let handlers = el.handlers || (el.handlers = {});
  handlers = handlers[event] || (handlers[event] = []);
  if (!handlers.length) {
    el.addEventListener(event, e => triggerEvents(el, event, handlers, e), bubble);
  }
  return handlers;
}

function triggerEvents(sender, event, eventHandlers, e) {
  eventHandlers.forEach(handler => {
    if (!handler.selector) {
      return handler.callback.call(sender, e, sender);
    }
    const target = e.target && e.target.closest && e.target.closest(handler.selector);
    if (target) {
      if ((event == 'mouseout' || event == 'mouseover') && target.contains(e.relatedTarget)) return;
      handler.callback.call(target, e, target);
    }
  });
}

export const jSlim = {
  dom: (_ => {
    const div = document.createElement('DIV');
    function pull(input, push) {
      div.innerHTML = input;
      input = push();
      div.innerHTML = '';
      return input;
    }
    return {
      load: html => pull(html, () => Array.apply(null, div.children)),
      decodeEntities: string => pull(string, () => div.innerText)
    };
  })(),
  bind: (el, event, func, bubble) => getHandlers(el, event, bubble).push({
		callback: func
	}),
  on: (el, event, selector, func, bubble) => getHandlers(el, event, bubble).push({
		selector: selector,
		callback: func
	}),
  each: (arrLike, func, thisArg) => Array.prototype.forEach.call(arrLike, func, thisArg),
  all: function(el, selector, func, thisArg) {
    if (typeof el == 'string') return jSlim.all(document, el, selector, func);
    return jSlim.each((el || document).querySelectorAll(selector), func, thisArg);
  },
  ready: func => {
    if (document.readyState !== 'loading') return func();
    jSlim.bind(document, 'DOMContentLoaded', func);
  },
  offset: element => {
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
};

export function bindAll(el, handlers, bubble) {
  Object.keys(handlers).forEach(key => {
    el.addEventListener(key, handlers[key], bubble);
  });
}
