export const Key = {
  ENTER: 13, ESC: 27, SPACE: 32, COMMA: 188, BACKSPACE: 8, Z: 90, Y: 89,
  LEFT: 37, RIGHT: 39
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

export function stopPropa(ev) {
  ev.stopPropagation();
}

export function extendObj(onto, overrides) {
  let keys = Object.keys(overrides), i = keys.length;
  for (; i--;) onto[keys[i]] = overrides[keys[i]];
  return onto;
}

export function extendFunc(Parent, overrides) {
  function Child() {};
  Child.prototype = extendObj(new Parent(), overrides);
  Child.Super = Parent.prototype;
  return Child;
}

export function copyOfObj(obj) {
  return extendObj({}, obj);
}

export function unionObj(one, two) {
  return extendObj(copyOfObj(one), two);
}
