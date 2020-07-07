export function triggerDrop(el, state) {
  requestAnimationFrame(() => {
    el.innerHTML = '<i class="fa"></i>';
    el.firstElementChild.classList.add(`fa-${state}`);
    el.classList.remove('hidden');
    requestAnimationFrame(() => {
      el.classList.add('hidden');
    });
  });
}
