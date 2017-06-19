import { ajax } from './ajax.js';

function slideOut(holder) {
  var h = holder.find('.group.active').height();
  holder.css('min-height', h);
  holder.css('max-height', h + 10);
  if (holder.hasClass('shown')) {
    holder.removeClass('shown');
  } else {
    $('.slideout.shown').removeClass('shown');
    holder.addClass('shown');
  }
  return holder;
}

function slideAcross(me, direction) {
  var form = me.parents('.slide-group');
  var to = form.find('.group[data-stage=' + me[0].dataset.to + ']');
  if (to.length) {
    form[0].dataset.offset = (parseInt(form[0].dataset.offset) || 0) + direction;
    var from = form.find('.active');
    from.removeClass('active');
    if (direction > 0) {
      from.after(to);
    } else {
      from.before(to);
    }
    
    to.addClass('active');
    setTimeout(function() {
      var diffH = form.height() - (from.height() - to.height());
      
      form.css('min-height', diffH);
      form.css('max-height', diffH);
      form.addClass('animating');
      form.find('.group').css('transform', 'translate(' + (-100 * form[0].dataset.offset) + '%,0)');
      setTimeout(function() {
        form.removeClass('animating');
        form.css('max-height', '');
      }, 500);
    }, 1);
  }
}

$(document).on('click', '.slider-toggle', function(e) {
  var me = $(this);
  var holder = $(this.dataset.target);
  if (me.hasClass('loadable') && !me.hasClass('loaded')) {
    me.addClass('loaded');
    ajax(this.dataset.url, function(json) {
      holder[0].innerHTML = json.content;
      holder.find('script').each(function() {
        var cs = document.createElement('SCRIPT');
        cs.textContent = '(function(){' + this.innerText + '}).apply({})';
        cs.onload = cs.onerror = function() {
          cs.parentNode.removeChild(cs);
        };
        this.parentNode.removeChild(this);
        document.head.appendChild(cs);
      });
      slideOut(holder);
    });
  } else {
    slideOut(holder);
  }
  e.preventDefault();
});

$(document).on('click', '.slide-holder .goto.slide-right', function() {
  slideAcross($(this), 1);
});

$(document).on('click', '.slide-holder .goto.slide-left', function() {
  slideAcross($(this), -1);
});

// app/views/layouts/_reporter.html.erb
window.slideAcross = slideAcross;

export { slideOut, slideAcross };
