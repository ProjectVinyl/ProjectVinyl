/*
 * Utility to capture clicks during drag and drop operations.
 */
function captureClick(ev) {
  ev.preventDefault();
}

export function captureClicks() {
  window.addEventListener('click', captureClick, true);

  return () => {
    requestAnimationFrame(() => {
      window.removeEventListener('click', captureClick, true);
    });
  };
}
