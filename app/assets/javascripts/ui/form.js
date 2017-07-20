import { uploadForm } from '../utils/progressform';
import { jSlim } from '../utils/jslim';

jSlim.on(document, 'submit', 'form.async', function(event) {
  uploadForm(this, event);
});
