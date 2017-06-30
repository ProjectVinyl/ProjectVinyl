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
        return pull(html, function() {
          return div.innerText;
        });
      }
    }
  })(),
  delegateEv: function(selector, func) {
    return function(e) {
      var target = e.target;
      while(target != null && target != document) {
        if (target.matches(selector)) {
            return func.call(target, e);
        }
        target = target.parentNode;
      }
    };
  },
  on: function(el, event, selector, func) {
    func = jSlim.delegateEv(selector, func);
    el.addEventListener(event, func);
    return func;
  },
  each: function(arrLike, func, thisArg) {
    return Array.prototype.forEach.call(arrLike, func, thisArg);
  },
  all: function(selector, func, thisArg) {
    return jSlim.each(document.querySelectorAll(selector), func, thisArg);
  },
  ready: function(func) {
    document.addEventListener('DOMContentLoaded', func);
  }
};

export { jSlim };