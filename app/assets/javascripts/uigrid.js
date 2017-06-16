var resizeGrid = (function() {
  
  function calculateNewWidth(grid, beside) {
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
  
  function calculatePageSplit(grid, beside) {
    var b = beside.offset().top + beside.height() + 10;
    
    grid.find('.page').each(function() {
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
  
  return function(grid, beside) {
    grid.find('.page.virtual').each(function() {
      var me = $(this);
      me.prev().removeClass('split').find('ul').append(me.find('li'));
    }).remove();
    
    grid.css('width', '');
    
    if (beside.width() > 0) {
      calculateNewWidth(grid, beside);
    }
    
    calculatePageSplit(grid, beside);
  };
})();

$(function() {
  if ($('.grid-root').length) {
    $win.on('resize', function() {
      resizeGrid($('.column-left'), $('.column-right'));
    });
    
    $doc.on('ready', function() {
      resizeGrid($('.column-left'), $('.column-right'));
    });
  }
});