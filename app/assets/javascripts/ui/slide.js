import { ajax } from '../utils/ajax.js';
import { Callbacks } from '../callbacks.js';
import { jSlim } from '../utils/jslim.js';

function slideOut(holder) {
  var h = holder.querySelector('.group.active').offsetHeight;
  holder.style.minHeight = h + 'px';
  holder.style.maxHeight = (h + 10) + 'px';
  if (holder.classList.contains('shown')) {
    holder.classList.remove('shown');
  } else {
    jSlim.all('.slideout.shown', function(el) {
      el.classList.remove('shown');
    });
    holder.classList.add('shown');
  }
  return holder;
}

function slideAcross(me, direction) {
  var form = me.closest('.slide-group');
  
  var to = form.querySelector('.group[data-stage=' + me.dataset.to + ']');
  if (!to) return;
  
  form.dataset.offset = (parseInt(form.dataset.offset) || 0) + direction;
  
  var from = form.querySelector('.active');
  if (from) {
    from.classList.remove('active');
    if (direction > 0) {
      from.parentNode.insertBefore(to, from.nextSibling);
    } else {
      from.parentNode.insertBefore(to, from);
    }
  }
  
  to.classList.add('active');
  
  setTimeout(function() {
    var diffH = form.offsetHeight - (from.offsetHeight - to.offsetHeight);
    
    form.style.maxHeight = form.style.minHeight = diffH + 'px';
    form.classList.add('animating');
    jSlim.all(form, '.group', function(el) {
      el.style.transform = 'translate(' + (-100 * form.dataset.offset) + '%,0)';
    });
    setTimeout(function() {
      form.classList.remove('animating');
      form.style.maxHeight = '';
    }, 500);
  }, 1);
}

jSlim.on(document, 'click', '.slider-toggle', function(e) {
  var url = this.dataset.url;
  var callback = this.dataset.callback;
  var holder = document.querySelector(this.dataset.target);
  if (this.classList.contains('loadable') && !this.classList.contains('loaded')) {
    this.classList.add('loaded');
    ajax.get(url).json(function(json) {
      holder.innerHTML = json.content;
      Callbacks.execute(callback);
      slideOut(holder);
    });
  } else {
    slideOut(holder);
  }
  e.preventDefault();
});

jSlim.on(document, 'click', '.slide-holder .goto.slide-right', function() {
  slideAcross(this, 1);
});

jSlim.on(document, 'click', '.slide-holder .goto.slide-left', function() {
  slideAcross(this, -1);
});

export { slideOut, slideAcross };
