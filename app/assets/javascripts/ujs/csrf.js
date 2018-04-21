
export function csrfToken() {
  const token = document.querySelector('meta[name="csrf-token"]');
  return token && token.content;
}

export function csrfParam() {
  const param = document.querySelector('meta[name="csrf-param"]');
  return param && param.content;
}

export function csrfHeaders(method) {
  return {
    method: method,
    credentials: 'same-origin',
    headers: {
      'Content-Type': method == 'GET' ? 'application/x-www-form-urlencoded' : 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': csrfToken()
    }
  };
}

function sameOrigin(url) {
  const a = document.createElement('a');
  a.href = url;
  return window.location.origin === a.origin;
}

document.addEventListener('submit', e => {
  const form = e.target.closest('form');
  
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
