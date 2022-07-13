export const Key = {
  ENTER: 13,
  ESC: 27,
  SPACE: 32,
  COMMA: 188,
  BACKSPACE: 8,
  Z: 90,
  Y: 89,
  M: 77,
  END: 35,
  HOME: 36,
  LEFT: 37, UP: 38, RIGHT: 39, DOWN: 40
};

export function getNumberKeyValue(keyCode) {
  return keyCode - 48;
}
export function isNumberKey(keyCode) {
  return keyCode >= 48 && keyCode <= 57;
}
