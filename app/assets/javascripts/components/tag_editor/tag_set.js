
export function tagSet(arr) {
  const toS = a => (a.name || a.toString()).trim();
  arr.baked = function() {
    return this.map(toS);
  };
  arr.join = function() {
    return Array.prototype.join.apply(this.baked(), arguments);
  };
  arr.indexOf = function(e, i) {
    const result = Array.prototype.indexOf.apply(this, arguments);
    return result > -1 ? result : Array.prototype.indexOf.call(this.baked(), toS(e), i);
  };
  arr.remove = function(item) {
    this.splice(this.indexOf(item), 1);
  };
  return arr;
}
