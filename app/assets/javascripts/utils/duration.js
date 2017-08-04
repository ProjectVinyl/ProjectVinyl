function round(num, precision) {
  precision = Math.pow(10, precision || 0);
  return Math.round(num * precision) / precision;
}

function Duration(seconds, delimiter) {
  this.delimiter = delimiter || ' ';
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
    var s = [];
    if (this.days) s.push(this.days + 'd');
    if (this.hours) s.push(this.hours + 'h');
    if (this.minutes) s.push(this.minutes + 'm');
    if (this.seconds && !s.length) s.push(this.seconds + 's');
    return s.join(this.delimiter);
  },
  valueOf: function() {
    return this.time;
  }
};

// converts a time integer to hh:mm:ss format
function toHMS(time) {
  const times = [];
  time = Math.floor(time);
  while (time >= 60) {
    times.shift(time % 60);
    time = Math.floor(time / 60);
  }
  times.shift(time);
  if (times.length < 2) times.shift(0);
  return times.join(':');
}

export { Duration, toHMS };
