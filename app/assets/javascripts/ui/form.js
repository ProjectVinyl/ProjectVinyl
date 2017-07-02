import { ajax } from '../utils/ajax.js';
import { jSlim } from '../utils/jslim.js';

jSlim.ready(() => {
  const forms = [].slice.call(document.querySelectorAll('form.async'));

  forms.forEach(f => {
    f.addEventListener('submit', e => ajax.form(f, e));
  });
});
