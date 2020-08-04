/*
 * Dirty hack
 */
document.addEventListener('click', event => submitAction(event, 'a[data-method], button[data-method]'));
document.addEventListener('change', event => submitAction(event, 'select[data-method]', true));

function submitAction(event, selector, ignoreMouse) {
  const a = event.target.closest(selector);

  // Only left click allowed
  if (!a || (!ignoreMouse && event.button !== 0)) return;

  const url = a.href || a.dataset.url;
  const method = a.dataset.method;

  const form = document.createElement('form');

  form.action = url;
  form.method = 'POST';
  form.dataset.method = method;
  form.style.display = 'none';
  form.appendChild(makeInput('_method', method));

  if (a.value && a.name) {
    form.appendChild(makeInput(a.name, a.value));
  }

  document.body.appendChild(form);
  event.preventDefault();

  // Dispatch an event so the auth token can be appended
  form.dispatchEvent(new Event('submit', event));
  // Submit the form
  form.submit();
}

function makeInput(name, value) {
  const input = document.createElement('input');
  input.type = 'hidden';
  input.name = name;
  input.value = value;
  return input;
}
