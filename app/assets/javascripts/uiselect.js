$(document).on('change', '.message_select', function() {
  if ($('input.message_select:checked').length) {
    $('#batch_ops').removeClass('disabled');
  } else {
    $('#batch_ops').addClass('disabled');
  }
});