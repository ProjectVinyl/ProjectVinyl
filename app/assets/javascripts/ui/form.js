import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';

jSlim.ready(() => {
  const forms = [].slice.call(document.querySelectorAll('form.async'));

  forms.forEach(f => {
    f.addEventListener('submit', e => ajax.form(f, e));
  });
});
