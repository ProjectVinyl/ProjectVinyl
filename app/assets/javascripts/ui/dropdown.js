import { jSlim } from '../utils/jslim';

const Popout = {
  toggle: function(sender) {
    if (sender && !sender.classList.contains('pop-out-shown')) {
      this.show(sender);
    } else {
      this.hide(sender);
    }
  },
  show: function(sender) {
    var content = sender.querySelector('.pop-out');
    const left = jSlim.offset(content).left;
    
    this.hideAll();
    sender.classList.add('pop-out-shown');
    sender.classList.remove('pop-left');
    sender.classList.remove('pop-right');
    
    if (left + content.clientWidth > document.documentElement.clientWidth) {
      sender.classList.add('pop-left');
    }
    if (left < 0) {
      sender.classList.add('pop-right');
    }
  },
  hide: function(sender) {
    sender.classList.remove('pop-out-shown');
  },
  hideAll: function() {
    jSlim.all('.pop-out-shown:not(:hover)', this.hide);
  }
};

jSlim.on(document, 'touchstart', '.drop-down-holder:not(.hover), .mobile-touch-toggle:not(.hover)', function(e) {
  e.preventDefault();
  
  var self = this;
  // ffs https://www.chromestatus.com/features/5093566007214080
  
  ['touchstart', 'touchmove'].forEach(t => {
    this.addEventListener(t, clos, { passive: false });
    document.addEventListener(t, clos, { passive: false });
  });
  
  this.classList.add('hover');
  
  function clos(e) {
    if (e.target.closest('a')) {
      return; // Links should only be triggered on touch when the drop-down is already open
    }
    
    self.classList.remove('hover');
    
    ['touchstart', 'touchmove'].forEach(function(t) {
      self.removeEventListener(t, clos);
      document.removeEventListener(t, clos);
    });
    
    e.preventDefault();
    e.stopPropagation();
  }
}, { passive: false });

jSlim.on(document, 'click', '.pop-out-toggle', function(e) {
  if (e.which != 1) return;
  Popout.toggle(this.closest('.popper'));
  e.preventDefault();
});

document.addEventListener('mousedown', function() {
  Popout.hideAll();
});
