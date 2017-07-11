import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';

jSlim.on(document, 'submit', 'form.async', function(event) {
  ajax.form(this, event);
});
