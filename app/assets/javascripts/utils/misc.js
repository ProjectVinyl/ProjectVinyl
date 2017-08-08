export const Key = {
  ENTER: 13, ESC: 27, SPACE: 32, COMMA: 188, BACKSPACE: 8, Z: 90, Y: 89
};

export function toBool(string) {
  return string && string.length && (string == '1' || string.toLowerCase() == 'true');
}

export function tryUnmarshal(data, fallback) {
  try {
    return JSON.parse(data);
  } catch(ignored) {}
  return fallback === undefined ? data : fallback;
}


// FIXME: why is it necessary to also stopPropagation?
// Utility function, used all over the place. Move it if you like.
export function halt(ev) {
  ev.preventDefault();
  ev.stopPropagation();
}

export function extendObj(onto, overrides) {
  let keys = Object.keys(overrides), i = keys.length;
  for (; i--;) onto[keys[i]] = overrides[keys[i]];
  return onto;
}

export function makeExtensible(Parent) {
  Parent.extend = function(Child, overrides) {
    Child.prototype = extendObj(new this(), overrides);
    Child.Super = this.prototype;
    Child.extend = this.extend;
  };
}

export function copyOfObj(obj) {
  return extendObj({}, obj);
}

export function unionObj(one, two) {
  return extendObj(copyOfObj(one), two);
}
