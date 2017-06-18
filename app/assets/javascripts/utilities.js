(function() {
  window.Key = {
    ENTER: 13, ESC: 27, COMMA: 188, BACKSPACE: 8, Z: 90, Y: 89
  };

  window.$doc = $(document);
  window.$win = $(window);

  document.windowFocused = false;
  $win.on('focus', function() {
    document.windowFocused = true;
  }).on('blur', function() {
    document.windowFocused = false;
  });
  
  var div = document.createElement('DIV');
  window.decodeEntities = function(string) {
    div.innerHTML = string;
    return div.innerText;
  };
  
  window.toBool = function toBool(string) {
    return string && string.length && (string == '1' || string.toLowerCase() == 'true');
  };
  
  window.round = function round(num, precision) {
    precision = Math.pow(10, precision || 0);
    return Math.round(num * precision) / precision;
  };
  
  window.timeoutOn = function timeoutOn(target, func, time) {
    return setTimeout(bind(target, func), time);
  };

  window.intervalOn = function intervalOn(target, func, time) {
    return setInterval(bind(target, func), time);
  };
  
  window.bind = function bind(target, func) {
    return function() {
      return func.apply(target, arguments);
    };
  };
  
  window.iteration = function iteration(arr, func, target) {
    return function(thisArg) {
      each(arr, func, thisArg || target);
    };
  };
  
  window.collect = function collect(arr, func, thisArg) {
    var result = [];
    each(arr, function() {
      result.push(func.call(this));
    }, thisArg);
    return result;
  };
  
  window.extendObj = function extendObj(onto, overrides) {
    var keys = Object.keys(overrides), i = keys.length;
    for (; i--;) onto[keys[i]] = overrides[keys[i]];
    return onto;
  };
  
  function each(arr, func, thisArg) {
    var i = arr.length, j = 0;
    for (; i--; j++) {
      if (func.apply(thisArg || arr[j], [arr, j]) === false) return arr;
    }
    return arr;
  };
  window.each = each;
})();
