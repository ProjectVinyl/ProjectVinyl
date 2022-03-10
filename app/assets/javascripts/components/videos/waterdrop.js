export function triggerDrop(el, state) {
  if (!el) {
    return;
  }

  requestAnimationFrame(() => {
    el.innerHTML = '<i class="fa"></i>';
    el.firstElementChild.classList.add(`fa-${state}`);
    el.classList.remove('hidden');
    requestAnimationFrame(() => {
      el.classList.add('hidden');
    });
  });
}
