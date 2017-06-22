const Key = {
  ENTER: 13, ESC: 27, SPACE: 32, COMMA: 188, BACKSPACE: 8, Z: 90, Y: 89
};

const div = document.createElement('DIV');
function decodeEntities(string) {
  div.innerHTML = string;
  return div.innerText;
}

function toBool(string) {
  return string && string.length && (string == '1' || string.toLowerCase() == 'true');
}

function extendObj(onto, overrides) {
  let keys = Object.keys(overrides), i = keys.length;
  for (; i--;) onto[keys[i]] = overrides[keys[i]];
  return onto;
}

function indirectEventFunc(selector, func) {
  return function(e) {
    var target = e.target;
    while(target != null && target != document) {
      if (target.matches(selector)) {
          return func.call(target, e);
      }
      target = target.parentNode;
    }
  };
}

function ready(func) {
  document.addEventListener('DOMContentLoaded', func);
}

export { Key, decodeEntities, toBool, extendObj, indirectEventFunc, ready };
