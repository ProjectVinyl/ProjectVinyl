import { uploadForm } from '../utils/progressform';
import { jSlim } from '../utils/jslim';

jSlim.on(document, 'submit', 'form.async', (e, target) => {
  e.preventDefault();
  uploadForm(target);
});
