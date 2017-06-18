window.paginator = (function() {
  function requestPage(context, page) {
    if (page == context[0].dataset.page) return;
    context[0].dataset.page = page;
    page = parseInt(page);
    context.find('ul').addClass('waiting');
    context.find('.pagination .pages .button.selected').removeClass('selected');
    ajax.get(context[0].dataset.type + '?page=' + page + (context[0].dataset.args ? '&' + context[0].dataset.args : ''), function(json) {
      populatePage(context, json);
    }, {});
  }
  
  function populatePage(context, json) {
    var container = context.find('ul');
    container.html(json.content);
    container.removeClass('waiting');
    context[0].dataset.page = json.page;
    context.find('.pagination').each(function() {
      repaintPages($(this), json.page, json.pages);
    });
  }
  
  function repaintPages(context, page, pages) {
    var index = page > 4 ? page - 4 : 0;
    var id = context.attr('data-id');
    context.find('.pages .button').each(function() {
      if (index > page + 4 || index > pages) {
        $(this).remove();
      } else {
        this.dataset.pageTo = index;
        this.href = '?' + QueryParameters.current.clone().setItem(id, index + 1).toString();
        this.innerText = index + 1;
        if (index == page) {
          this.classList.add('selected');
        }
      }
      index++;
    });
    context = context.find('.pages');
    while (index <= page + 4 && index <= pages) {
      context.append('<a class="button' + (index == page ? ' selected' : '') + '" data-page-to="' + index + '" href="?' + QueryParameters.current.clone(id, ++index).toString() + '">' + index + '</a> ');
    }
    QueryParameters.current.setItem(id, page + 1);
  }
  
  return {
    repaint: function(context, json) {
      context.find('.pagination .pages .button.selected').removeClass('selected');
      populatePage(context, json);
    },
    go: function(button) {
      requestPage(button.closest('.paginator'), button[0].dataset.pageTo);
      if (!button.hasClass('selected')) button.parent().removeClass('hover');
    }
  };
})();

$doc.on('click', '.pagination .pages .button, .pagination .button.left, .pagination .button.right', function(e) {
  if (!e.ctrlKey && !e.shiftKey) {
    paginator.go($(this));
    e.preventDefault();
  }
});
