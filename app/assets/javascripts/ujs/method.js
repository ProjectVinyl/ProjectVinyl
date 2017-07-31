document.addEventListener('click', event => {
  const a = event.target.closest('a[data-method]');
  
  // Only left click allowed
  if (event.button !== 0) return;
  if (!a) return;
  
  const url = a.href;
  const method = a.dataset.method;
  
  const form = document.createElement('form');
  const input = document.createElement('input');
  
  form.action = url;
  form.method = 'POST';
  form.dataset.method = method;
  form.style.display = 'none';
  
  if (a.dataset.remote) form.dataset.remote = 'true';
  
  input.type = 'hidden';
  input.name = '_method';
  input.value = method;
  
  form.appendChild(input);
  
  document.body.appendChild(form);
  event.preventDefault();
  
  form.dispatchEvent(new Event('submit'));
});
