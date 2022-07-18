import { popupError } from '../components/popup';

export function checkFormPrerequisits(group) {
  const required = group.querySelectorAll('[required], [data-required]');
  for (let i = 0; i < required.length; i++) {
    if (!validateInput(required[i])) {
      popupError('One or more required fields need to be filled in.');
      required[i].focus();
      return false;
    }
  }
  return true;
}

function validateInput(input) {
  if (input.tagName == 'INPUT' && input.type == 'checkbox') {
    return input.checked;
  }

  if (input.tagName == 'INPUT' || input.tagName == 'TEXTAREA') {
    return input.value && input.value.length;
  }

  const children = input.querySelectorAll('input');
  for (let i = 0; i < children.length; i++) {
    if (validateInput(children[i])) {
      return true;
    }
  }

  return false;
}
