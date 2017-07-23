import { uploadForm } from '../utils/progressform';
import { jSlim } from '../utils/jslim';

jSlim.on(document, 'submit', 'form.async', function(e) {
  e.preventDefault();
  uploadForm(this);
});
