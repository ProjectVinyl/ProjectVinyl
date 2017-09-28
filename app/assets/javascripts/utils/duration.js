import { round } from './math';

export function Duration(timeframe, delimiter) {
  this.delimiter = delimiter || ' ';
  this.seconds = this.timeframe = timeframe || 0;
  this.days = extractTimeUnit(this, 60 * 60 * 24);
  this.hours = extractTimeUnit(this, 60 * 60);
  this.minutes = extractTimeUnit(this, 60);
  this.seconds = round(this.seconds, 2);
}
Duration.prototype = {
  toString: function() {
    const s = [];
    if (this.days) s.push(this.days + 'd');
    if (this.hours) s.push(this.hours + 'h');
    if (this.minutes) s.push(this.minutes + 'm');
    if (this.seconds) s.push(this.seconds + 's');
    return s.join(this.delimiter);
  },
  valueOf: function() {
    return this.timeframe;
  }
};

function extractTimeUnit(duration, modulus) {
  if (seconds < modulus) return 0;
  const seconds = Math.floor(duration.seconds / modulus);
  duration.seconds -= seconds * modulus;
  return seconds;
}

// converts a time integer to hh:mm:ss format
export function toHMS(timeframe, delimiter) {
  const times = [];
  timeframe = Math.floor(timeframe);
  while (timeframe >= 60) {
    times.unshift(timeframe % 60);
    timeframe = Math.floor(timeframe / 60);
  }
  times.unshift(timeframe);
  if (times.length < 2) times.unshift(0);
  return times.join(delimiter || ':');
}
