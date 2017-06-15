const Key = {
  ENTER: 13, ESC: 27, COMMA: 188, BACKSPACE: 8, Z: 90, Y: 89
};

const $doc = $(document);

let window_focused = false;
$(window).on('focus', () => {
  window_focused = true;
}).on('blur', () => {
  window_focused = false;
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
  toString() {
    let s = '';
    if (this.days > 0) s += `${this.days}d `;
    if (this.hours > 0) s += `${this.hours}h `;
    if (this.minutes > 0) s += `${this.minutes}m `;
    if (s.length == 0 || this.seconds > 0) s += `${this.seconds}s`;
    return s.trim();
  },
  valueOf() {
    return this.time;
  }
};

const decode_entities = (function() {
  const div = document.createElement('DIV');
  return function(string) {
    div.innerHTML = string;
    return div.innerText;
  };
}());

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

function extendObj(onto, overrides) {
  const keys = Object.keys(overrides);
  for (let i = keys.length; i--;) {
    onto[keys[i]] = overrides[keys[i]];
  }
  return onto;
}
