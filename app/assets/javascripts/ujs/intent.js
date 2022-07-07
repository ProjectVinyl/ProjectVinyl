import { makeInput } from './method';

document.addEventListener('click', e => {
  const target = e.target;
  const form = e.target.closest('form');

  if (target.type != 'submit'
  || !target.name
  || (target.tagName != 'BUTTON' && target.tagName != 'INPUT')) {
    return;
  }

  if (form._intent) {
    form._intent.value = target.name;
  } else {
    form.appendChild(makeInput('_intent', target.name));
  }
  
  if (target.dataset.formMethod) {
    if (form._method) {
      form._method.value = target.dataset.formMethod;
    } else {
      form.appendChild(makeInput('_method', target.dataset.formMethod));
    }
  }
});
