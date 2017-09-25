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

export function bindAll(el, handlers, bubble) {
  Object.keys(handlers).forEach(key => {
    bindEvent(el, key, handlers[key], bubble);
  });
}

export function delegateAll(el, selector, handlers, bubble) {
  Object.keys(handlers).forEach(key => {
    addDelegatedEvent(el, key, selector, handlers[key], bubble);
  });
}

export function bindEvent(el, event, func, bubble) {
  getHandlers(el, event, bubble).push({ callback: func });
}

export function once(node, type, listener) {
  function wrapper() {
    node.removeEventListener(type, wrapper);
    return listener.apply(this, arguments);
  }
  node.addEventListener(type, wrapper);
  return wrapper;
}

export function addDelegatedEvent(el, event, selector, func, bubble) {
  getHandlers(el, event, bubble).push({ selector: selector, callback: func });
}

export function ready(func) {
  if (document.readyState !== 'loading') return func();
  bindEvent(document, 'DOMContentLoaded', func);
}

export function halt(ev) {
  ev.preventDefault();
  ev.stopPropagation();
}
