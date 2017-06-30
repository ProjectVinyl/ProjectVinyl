function sizeFont(el, targetWidth) {
  var div = $('<div style="position:fixed;top:0;left:0;white-space:nowrap;background:#fff" />');
  div.css({
    'font-family': el.css('font-family'),
    'font-weight': el.css('font-weight'),
    'font-size-adjust': el.css('font-size-adjust')
  });
  div.text(el.text());
  el.css('font-size', '');
  var size = parseFloat(el.css('font-size'));
  div.css('font-size', size);
  
  $('body').append(div);
  
  var currentWidth = div.width();
  var factor = -1;
  while (currentWidth > targetWidth) {
    factor = targetWidth / currentWidth;
    size *= factor;
    div.css('font-size', size);
    currentWidth = div.width();
  }
  if (size < 5) size = 5;
  el.css('font-size', size);
  div.remove();
}

function resizeFont(el) {
  sizeFont(el, el.closest('.resize-holder').width());
}

function fixFonts() {
  $('h1.resize-target').each(function() {
    resizeFont($(this));
  });
}

$(window).on('resize', fixFonts);
$(fixFonts);

export { resizeFont };