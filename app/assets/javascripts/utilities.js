const Key = {
  ENTER: 13, ESC: 27, COMMA: 188, BACKSPACE: 8, Z: 90, Y: 89
};

const $doc = $(document);
const $win = $(window);

var windowFocused = false;
$win.on('focus', function() {
  windowFocused = true;
}).on('blur', function() {
  windowFocused = false;
});

function Duration(seconds) {
  this.time = seconds || 0;
  this.seconds = this.time;
  this.minutes = 0;
  this.hours = 0;
  this.days = 0;
  if (this.seconds >= (60 * 60 * 24)) {
    this.days = Math.floor(this.seconds / (60 * 60 * 24));
    this.seconds -= this.days * (60 * 60 * 24);
  }
  if (this.seconds >= (60 * 60)) {
    this.hours = Math.floor(this.seconds / (60 * 60));
    this.seconds -= this.hours * (60 * 60);
  }
  if (this.seconds >= 60) {
    this.minutes = Math.floor(this.seconds / 60);
    this.seconds -= this.minutes * 60;
  }
  this.seconds = round(this.seconds, 2);
}
Duration.prototype = {
  toString: function() {
    var s = '';
    if (this.days > 0) s += this.days + 'd ';
    if (this.hours > 0) s += this.hours + 'h ';
    if (this.minutes > 0) s += this.minutes + 'm ';
    if (s.length == 0 || this.seconds > 0) s += this.seconds + 's';
    return s.trim();
  },
  valueOf: function() {
    return this.time;
  }
};

(function() {
  var div = document.createElement('DIV');
  window.decodeEntities = function(string) {
    div.innerHTML = string;
    return div.innerText;
  };
})();

function toBool(string) {
  return string && string.length && (string == '1' || string.toLowerCase() == 'true');
}

function round(num, precision) {
  precision = Math.pow(10, precision || 0);
  return Math.round(num * precision) / precision;
}

function timeoutOn(target, func, time) {
  return setTimeout(bind(target, func), time);
}

function intervalOn(target, func, time) {
  return setInterval(bind(target, func), time);
}

function bind(target, func) {
  return function() {
    return func.apply(target, arguments);
  };
}

function iteration(arr, func) {
  return function() {
    each(arr, func);
  };
}

function each(arr, func) {
  var i = arr.length, j = 0;
  for (; i--; j++) {
    if (func.apply(arr[j], [arr, j]) === false) return arr;
  }
  return arr;
}

function collect(arr, func) {
  var result = [];
  each(arr, function() {
    result.push(func.call(this));
  });
  return result;
}

function extendObj(onto, overrides) {
  var keys = Object.keys(overrides), i = keys.length;
  for (; i--;) onto[keys[i]] = overrides[keys[i]];
  return onto;
}