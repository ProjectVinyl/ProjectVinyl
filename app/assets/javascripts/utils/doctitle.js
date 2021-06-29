
let focus = true;

function removePrefix() {
  if (document.title.indexOf('*') == 0) {
    document.title = document.title.replace('* ', '');
  }
}

function addPrefix() {
  if (document.title.indexOf('*') != 0) {
    document.title = `* ${document.title}`;
  }
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