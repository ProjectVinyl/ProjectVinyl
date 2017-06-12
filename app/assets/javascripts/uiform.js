$('form.async').on('submit', function(e) {
  ajax.form($(this), e);
});