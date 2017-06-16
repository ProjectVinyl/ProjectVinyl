var paginator = (function() {
  var hash = document.location.hash;
  var page = -2;
  var id = hash.match(/#\/([^/]+)/);
  if (id) {
    id = id[1];
    hash = hash.replace('/' + id + '/', '');
    if (hash.indexOf('#first') == 0) {
      page = 0;
    } else if (hash.indexOf('#last') == 0) {
      page = -1;
    } else {
      page = parseInt(hash.match(/#([0-9]+)/)[1]);
    }
    if (page > -2) {
      $(function() {
        var pagination = $('.pagination[data-id=' + id + ']');
        if (pagination.length) {
          return requestPage(pagination.closest('.paginator'), page - 1);
        }
        var tabSwitch = $('.tab-set.async a.button[data-target=' + id + ']');
        if (tabSwitch.length) {
          tabSwitch[0].dataset.page = page - 1;
          tabSwitch.click();
        }
      });
    }
  }
  
  function requestPage(context, page) {
    if (page == context[0].dataset.page) return;
    context[0].dataset.page = page;
    page = parseInt(page);
    context.find('ul').addClass('waiting');
    context.find('.pagination .pages .button.selected').removeClass('selected');
    ajax.get(context.attr('data-type') + '?page=' + context[0].dataset.page + '&' + context[0].dataset.args, function(json) {
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
        $(this).attr('data-page-to', index).attr('href', '#/' + id + '/' + (index + 1)).text(index + 1);
        if (index == page) {
          $(this).addClass('selected');
        }
      }
      index++;
    });
    context = context.find('.pages');
    while (index <= page + 4 && index <= pages) {
      context.append('<a class="button' + (index == page ? ' selected' : '') + '" data-page-to="' + index + '" href="#/' + id + '/' + ++index + '">' + index + '</a> ');
    }
    document.location.hash = '/' + id + '/' + (page + 1);
  }
  
  return {
    repaint: function(context, json) {
      context.find('.pagination .pages .button.selected').removeClass('selected');
      populatePage(context, json);
    },
    goto: function(button) {
      requestPage(button.closest('.paginator'), button.attr('data-page-to'));
      if (!button.hasClass('selected')) button.parent().removeClass('hover');
    }
  };
})();

$doc.on('click', '.pagination .pages .button, .pagination .button.left, .pagination .button.right', function() {
  paginator.goto($(this));
});