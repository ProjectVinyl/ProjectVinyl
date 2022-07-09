import { getHandlers } from './event_handlers';

export function bindAll(el, handlers, bubble) {
  Object.keys(handlers).forEach(key => {
    bindEvent(el, key, handlers[key], bubble);
  });
}

export function bindEvent(el, event, func, bubble) {
  getHandlers(el, event, bubble).push({ callback: func });
}

export function ready(func) {
  if (document.readyState !== 'loading') return func();
  bindEvent(document, 'DOMContentLoaded', func);
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

export function delegateAll(el, selector, handlers, bubble) {
  Object.keys(handlers).forEach(key => {
    addDelegatedEvent(el, key, selector, handlers[key], bubble);
  });
}

export function halt(ev) {
  ev.preventDefault();
  ev.stopPropagation();
}

export function dispatchEvent(event, data, sender) {
  (sender || document).dispatchEvent(new CustomEvent(event, {
    detail: { data: data }, bubbles: true, cancelable: true
  }));
  return data;
}