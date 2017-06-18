import { ajax } from './ajax.js';

$(function() {
  $('form.async').on('submit', function(e) {
    ajax.form($(this), e);
  });
});
