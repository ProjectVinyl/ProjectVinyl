$(function() {
  var searchInput = $('#search input');
  $('#search select').on('change', function() {
    var val = this.value;
    if (val == '0' || val == '2') {
      searchInput.attr({
        name: 'tagquery',
        placeholder: 'Tag Search'
      });
    } else {
      searchInput.attr({
        name: 'query',
        placeholder: 'Search'
      });
    }
  });
  
  $('#search_type').on('change', function() {
    var val = this.value;
    $('#search_tags').css('display', (val == '0' || val == '2') ? '' : 'none');
  });
});