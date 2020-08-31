const test = navigator.userAgent.match(/Firefox\/([0-9]+(\.[0-9]+))/);

if (test && test.length > 1) {
  if (parseFloat(test[1]) <= 80) {
    document.querySelector('.context-3d').classList.add('no-3d');
  }
}
