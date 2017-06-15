$(() => {
  $('#search select').on('change', function() {
    const val = $(this).val();
    if (val == '0' || val == '2') {
      $('#search input').attr({name: 'tagquery', placeholder: 'Tag Search'});
    } else {
      $('#search input').attr({name: 'query', placeholder: 'Search'});
    }
  });
});
