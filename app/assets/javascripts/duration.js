function round(num, precision) {
  precision = Math.pow(10, precision || 0);
  return Math.round(num * precision) / precision;
}

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

export { Duration };
