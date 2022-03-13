
let pings = 0;
let focus = true;

let originalTitle;

function removePrefix() {
  pings = 0;
  if (!originalTitle) {
    originalTitle = document.title;
  }
  document.title = originalTitle;
}

function addPrefix() {
  pings++;

  if (!originalTitle) {
    originalTitle = document.title;
  }

  document.title = `(${pings}) ${originalTitle}`;
}

export function togglePrefix(on) {
  if (!focus && on) {
    return addPrefix();
  }
  removePrefix();
}

window.addEventListener('focus', () => {
  focus = true;
  removePrefix();
});
window.addEventListener('blur', () => {
  focus = false;
});