document.addEventListener('click', event => {
  const target = event.target.closest('a[data-confirm], button[data-confirm], input[data-confirm]');
  if (!target) return;

  const message = target.dataset.confirm;

  if (!window.confirm(message)) {
    event.stopPropagation();
    event.stopImmediatePropagation();
    event.preventDefault();
  }
});
