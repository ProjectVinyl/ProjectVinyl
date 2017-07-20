export function csrfToken() {
  const  token = document.querySelector('meta[name="csrf-token"]');
  return token && token.content;
}

export function csrfParam() {
  const  param = document.querySelector('meta[name="csrf-param"]');
  return param && param.content;
}

function sameOrigin(url) {
  const a = document.createElement('a');
  a.href = url;
  return window.location.origin === a.origin;
}

document.addEventListener('submit', e => {
  const form = e.target.closest('form');

  // These need no further action
  if (form.matches('form[data-remote]')) return;
  if (!form.method || form.method.toUpperCase() === 'GET') return;
  if (!sameOrigin(form.action)) return;

  const param = csrfParam();
  const token = csrfToken();

  if (param && token && !form.querySelector(`input[name="${param}"]`)) {
    const input = document.createElement('input');
    input.type  = 'hidden';
    input.name  = param;
    input.value = token;

    form.appendChild(input);
  }
}, true);