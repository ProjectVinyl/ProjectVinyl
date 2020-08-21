export function round(num, precision) {
  precision = Math.pow(10, precision || 0);
  return Math.round(num * precision) / precision;
}

export function linearInterpolate({x1, y1}, {x2, y2}, x) {
  const m = (y2 - y1)/(x2 - x1);
  return (m*(x - x1)) + y1;
}

export function ease(t) {
  return (1 - Math.cos(t * Math.PI)) / 2;
}

export function clamp(x, min, max) {
  return Math.max(Math.min(x, max), min);
}

export function clampPercentage(p, max) {
  return clamp(p, 0, max) / max;
}

export function divmod(number, div) {
  return [
    Math.floor(number / div),
    Math.floor(number % div)
  ]
}
