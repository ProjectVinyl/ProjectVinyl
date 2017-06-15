function slideOut(holder) {
  const h = holder.find('.group.active').height();
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
  const form = me.parents('.slide-group');
  const to = form.find(`.group[data-stage=${me.attr('data-to')}]`);
  if (to.length) {
    const offset = (parseInt(form.attr('data-offset')) || 0) + direction;
    form.attr('data-offset', offset);
    const from = form.find('.active');
    const fromH = from.height();
    const formH = form.height();
    from.removeClass('active');
    if (direction > 0) {
      from.after(to);
    } else {
      from.before(to);
    }
    to.addClass('active');
    setTimeout(() => {
      form.css('min-height', formH - (fromH - to.height()));
      form.css('max-height', formH - (fromH - to.height()));
      form.addClass('animating');
      form.find('.group').css('transform', `translate(${-100 * offset}%,0)`);
      setTimeout(() => {
        form.removeClass('animating');
        form.css('max-height', '');
      }, 500);
    }, 1);
  }
}

$doc.on('click', '.slider-toggle', function(e) {
  const me = $(this);
  const holder = $(me.attr('data-target'));
  if (me.hasClass('loadable') && !me.hasClass('loaded')) {
    me.addClass('loaded');
    ajax(me.attr('data-url'), json => {
      holder[0].innerHTML = json.content;
      holder.find('script').each(function() {
        const cs = document.createElement('SCRIPT');
        cs.textContent = `(function(){${this.innerText}}).apply({})`;
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

$doc.on('click', '.slide-holder .goto.slide-right', function() {
  slideAcross($(this), 1);
});

$doc.on('click', '.slide-holder .goto.slide-left', function() {
  slideAcross($(this), -1);
});
