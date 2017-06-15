function resizeGrid(grid, beside) {
  grid.find('.page.virtual').each(function() {
    var me = $(this);
    me.prev().removeClass('split').find('ul').append(me.find('li'));
  }).remove();
  grid.css('width', '');
  if (beside.width() > 0) {
    var width = grid.parent().innerWidth() - 195;
    var calculatedWidth = width + 1;
    var n = 10;
    do {
      calculatedWidth = 60 + (182 * n) + 45 * --n + 60;
    } while (calculatedWidth > width);
    grid.css('width', calculatedWidth + 'px');
    if (beside) {
      beside.css('width', (beside.parent().innerWidth() - (calculatedWidth + 15)) + 'px');
    }
  }
  var b = beside.offset().top + beside.height() + 10;
  var h = grid.offset().top;
  grid.find('.page').each(function(index) {
    var me = $(this);
    var t = me.offset().top;
    if (t < b && (t + me.outerHeight()) > b) {
      me.find('li').each(function() {
        var li = $(this);
        if (li.offset().top > b) {
          li.addClass('t');
          me.addClass('split');
          var nx = $('<section class="page virtual"><div class="group"><ul class="horizontal latest" /></div></section>');
          nx.find('ul').append($('.t, .t ~ li'));
          me.after(nx);
          li.removeClass('t');
          return false;
        }
      });
      return false;
    }
  });
}

$(function() {
  if ($('.grid-root').length) {
    $(window).on('resize', function() {
      resizeGrid($('.column-left'), $('.column-right'));
    });

    $(document).on('ready', function() {
      resizeGrid($('.column-left'), $('.column-right'));
    });
  }
});