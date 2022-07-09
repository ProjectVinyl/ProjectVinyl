
export function getHandlers(el, event, bubble) {
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
