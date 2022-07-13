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

function moveAcross(to, from, func) {
  Object.keys(from).forEach(key => to[key] = func(from[key]));
  return to;
}

export function remapObj(obj, func) {
  return moveAcross({}, obj, func);
}

export function extendObj(onto, overrides) {
  return moveAcross(onto, overrides, value => value);
}

export function extendFunc(Parent, Child, overrides) {
  Child.prototype = extendObj(copyOfObj(Parent.prototype), overrides);
  Child.Super = Parent.prototype;
  return Child;
}

export function copyOfObj(obj) {
  return extendObj({}, obj);
}

export function unionObj(one, two) {
  return extendObj(copyOfObj(one), two);
}
