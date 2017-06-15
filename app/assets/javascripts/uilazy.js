function lazyLoad(button) {
  const target = $(`#${button.attr('data-target')}`);
  const page = parseInt(button.attr('data-page')) + 1;
  button.addClass('working');
  ajax.get(button.attr('data-url'), json => {
    button.removeClass('working');
    if (json.page == page) {
      target.append(json.content);
      button.attr('data-page', page);
    } else {
      button.remove();
    }
  }, {
    page,
    id: button.attr('data-id')
  });
}

$doc.on('click', '.load-more button', function() {
  lazyLoad($(this));
});

$doc.on('click', '.mix a', function(e) {
  document.location.replace(`${$(this).attr('href')}&t=${$('#video .player')[0].getPlayerObj().video.currentTime}`);
  e.preventDefault();
});
