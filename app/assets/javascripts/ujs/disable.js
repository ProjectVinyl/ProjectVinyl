/*
 * TODO: Remove
 */
document.addEventListener('click', event => {
  const element = event.target;

  // left/middle click only
  if (event.button > 1) return;

  // do not disable if the element is a submit button and its form has invalid input elements.
  // since failed validations prevent the form from being submitted, we would lock the form permanently
  // by disabling the submit button even though the form was never submitted
  if (element.type === 'submit' && element.form && element.form.querySelector(':invalid') !== null) return;
  if (!element.matches('a[data-disable-with], button[data-disable-with], input[data-disable-with]')) return;

  element.innerHTML = element.dataset.disableWith;

  // delay is needed because Safari stops the submit if the button is immediately disabled
  requestAnimationFrame(() => element.disabled = 'disabled');
});
