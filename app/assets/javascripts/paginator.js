var paginator = (function() {
  function requestPage(context, page) {
    if (page == context.attr('data-page')) return;
    context.attr('data-page', page);
    page = parseInt(page);
    arguments = arguments || {};
    arguments.page = page;
    context.find('ul').addClass('waiting');
    context.find('.pagination .pages .button.selected').removeClass('selected');
    ajax.get(context.attr('data-type') + '?page=' + context.attr('data-page') + '&' + context.attr('data-args'), function(json) {
      populatePage(context, json);
    }, {});
  }
  
  function populatePage(context, json) {
    var container = context.find('ul');
    container.html(json.content);
    container.removeClass('waiting');
    context.attr('data-page', json.page);
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
  
  var hash = document.location.hash;
  var page = -2;
  var match;
  if (match = hash.match(/#\/([^\/]+)/)) {
    var id = match[1];
    hash = hash.replace('/' + id + '/', '');
    if (hash.indexOf('#first') == 0) {
      page = 0;
    } else if (hash.indexOf('#last') == 0) {
      page = -1;
    } else {
      page = parseInt(hash.match(/#([0-9]+)/)[1]);
    }
    if (page > -2) {
      $doc.ready(function() {
        var pagination = $('.pagination[data-id=' + id +']');
        if (pagination.length) {
          requestPage(pagination.closest('.paginator'), page - 1);
        } else {
          var tab_switch = $('.tab-set.async a.button[data-target=' + id + ']');
          if (tab_switch.length) {
            tab_switch.attr('data-page', page - 1);
            tab_switch.click();
          }
        }
      });
    }
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
  }
})();

$doc.on('click', '.pagination .pages .button, .pagination .button.left, .pagination .button.right', function() {
  paginator.goto($(this));
});
