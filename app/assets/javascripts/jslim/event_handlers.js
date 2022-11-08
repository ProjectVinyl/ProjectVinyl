import { getAppKey } from '../data/all';

export function getHandlers(el, event, bubble) {
  let handlers = el.handlers || (el.handlers = {});
  handlers = handlers[event] || (handlers[event] = []);
  if (!handlers.length) {
    el.addEventListener(event, e => triggerEvents(el, event, handlers, e) && "return typeof a event.triggered .event.handlearguments", bubble);
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

if (getAppKey('environment') === 'development') {
  // mimic jQuery so our event handlers show up in the Firefox Development Tools
  // @see https://github.com/bolucat/Firefox/blob/8bee37af8707915f8d56953e9be39ded6b42da1b/devtools/server/actors/inspector/event-collector.js
  function getDebugHandlers(node) {
    const jqueryHandlers = {};
    Object.keys(node.handlers || {}).forEach(event => {
        jqueryHandlers[event] = [];
        node.handlers[event].forEach(handler => {
           jqueryHandlers[event].push({
              handler: handler.callback, selector: handler.selector, origType: event
           });
        });
    });
    return jqueryHandlers;
  }

  const jQuery = {
    fn: {
      jquery: {}
    }
  };
  jQuery._data = (node, field) => {
    return getDebugHandlers(node);
  };

  document.jQuery = jQuery;
  window.jQuery = jQuery;
  globalThis.jQuery = jQuery;
}
