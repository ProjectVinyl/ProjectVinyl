var scrollTo = (function() {
  function scrollIntoView(me, container, viewport) {
    var offset = me.offset();
    var scrollpos = container.offset();
    container.animate({
      scrollTop: offset.top - scrollpos.top - viewport.height() / 2 + me.height() / 2,
      scrollLeft: offset.left - scrollpos.left - viewport.width() / 2 + me.width() / 2
    });
    return me;
  }
  
  return function(el, container, viewport) {
    el = $(el);
    if (!el.length) return el;
    return scrollIntoView(el, $(container || 'html, body'), $(viewport || window));
  };
})();