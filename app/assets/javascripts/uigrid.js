function resizeGrid(grid, beside) {
  grid.find('.page.virtual').each(function() {
    const me = $(this);
    me.prev().removeClass('split').find('ul').append(me.find('li'));
  }).remove();
  grid.css('width', '');
  if (beside.width() > 0) {
    const width = grid.parent().innerWidth() - 195;
    let calculatedWidth = width + 1;
    let n = 10;
    do {
      calculatedWidth = 60 + (182 * n) + 45 * --n + 60;
    } while (calculatedWidth > width);
    grid.css('width', `${calculatedWidth}px`);
    if (beside) {
      beside.css('width', `${beside.parent().innerWidth() - (calculatedWidth + 15)}px`);
    }
  }
  const b = beside.offset().top + beside.height() + 10;
  const h = grid.offset().top;
  grid.find('.page').each(function(index) {
    const me = $(this);
    const t = me.offset().top;
    if (t < b && (t + me.outerHeight()) > b) {
      me.find('li').each(function() {
        const li = $(this);
        if (li.offset().top > b) {
          li.addClass('t');
          me.addClass('split');
          const nx = $('<section class="page virtual"><div class="group"><ul class="horizontal latest" /></div></section>');
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

$(() => {
  if ($('.grid-root').length) {
    $(window).on('resize', () => {
      resizeGrid($('.column-left'), $('.column-right'));
    });

    $(document).on('ready', () => {
      resizeGrid($('.column-left'), $('.column-right'));
    });
  }
});
