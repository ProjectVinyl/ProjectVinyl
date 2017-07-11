export function linearInterpolate({x1, y1}, {x2, y2}, x) {
  const m = (y2 - y1)/(x2 - x1);
  return (m*(x - x1)) + y1;
}

export function ease(t) {
  return (1 - Math.cos(t * Math.PI)) / 2;
}
