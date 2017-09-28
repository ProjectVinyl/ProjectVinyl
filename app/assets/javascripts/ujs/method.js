/*
 * Dirty hack
 */

document.addEventListener('click', event => {
  const a = event.target.closest('a[data-method], button[data-method]');
  
  // Only left click allowed
  if (!a || event.button !== 0) return;
  
  const url = a.href || a.dataset.url;
  const method = a.dataset.method;
  
  const form = document.createElement('form');
  const input = document.createElement('input');
  
  form.action = url;
  form.method = 'POST';
  form.dataset.method = method;
  form.style.display = 'none';
  
  input.type = 'hidden';
  input.name = '_method';
  input.value = method;
  
  form.appendChild(input);
  
  document.body.appendChild(form);
  event.preventDefault();
  
  form.dispatchEvent(new Event('submit', event));
});
