$(function() {
  var banner = $('#banner');
  if (banner.length) {
    if (window.requestAnimationFrame) {
      
      animator();
    } else {
      console.log('RequestAnimationFrame not supported. Using scroll instead');
      $(window).on('scroll', scroller);
    }
  }
  
  function animator() {
    scroller();
    window.requestAnimationFrame(animator);
  }
  
  function scroller() {
    var top = window.scrollY;
    var width = window.innerWidth;
    if (top <= 200) banner.css('background-position', 'top calc(50% + ' + (top * 0.5) + 'px) ' + (width > 1300 ? 'left' : 'center') + ', top calc(50% + ' + (top * 0.5) + 'px) right');
  }
});
