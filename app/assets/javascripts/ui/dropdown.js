import { jSlim } from '../utils/jslim.js';

const Popout = {
  toggle(sender) {
    if (sender && sender.classList.contains('pop-out-shown')) {
      this.show(sender);
    } else {
      this.hideAll();
    }
  },
  show(sender) {
    const left = jSlim.offset(sender.content).left;
    
    this.hideAll();
    sender.classList.add('pop-out-shown');
    sender.classList.remove('pop-left');
    sender.classList.remove('pop-right');
    
    if (left + sender.content.clientWidth > document.documentElement.clientWidth) {
      sender.classList.add('pop-left');
    }
    if (left < 0) {
      sender.classList.add('pop-right');
    }
  },
  hideAll() {
    const shown = document.querySelector('.pop-out-shown');
    if (shown) shown.classList.remove('pop-out-shown');
  }
};

function delegate(node, event, selector, callback) {
  node.addEventListener(event, e => {
    const target = e.target.closest(selector);
    if (target) callback(target, e);
  }, { passive: false }); // ffs https://www.chromestatus.com/features/5093566007214080
}

jSlim.ready(() => {
  // FIXME what are these even doing here??
  delegate(document, 'focusin', 'label input, label select', target => {
    target.closest('label').classList.add('focus');
  });

  delegate(document, 'focusout', 'label input, label select', target => {
    target.closest('label').classList.remove('focus');
  })

  // FIXME what a clusterfuck
  delegate(document, 'touchstart', '.drop-down-holder:not(.hover), .mobile-touch-toggle:not(.hover)', (target, e) => {
    const lis = [].slice.call(target.querySelectorAll('a, li'));

    lis.forEach(li => {
      li.addEventListener('touchstart', stopPropa);
    });

    ['touchstart', 'touchmove'].forEach(t => {
      target.addEventListener(t, clos);
      document.addEventListener(t, clos);
    });
    
    target.classList.add('hover');
    e.preventDefault();
    e.stopPropagation(); // FIXME

    function stopPropa(e2) {
      e2.stopPropagation(); // FIXME
    }

    function clos(e3) {
      ['touchstart', 'touchmove'].forEach(t => {
        target.removeEventListener(t, clos);
        document.removeEventListener(t, clos);
      });

      target.classList.remove('hover');

      lis.forEach(li => {
        li.removeEventListener('touchstart', stopPropa);
      });

      e3.preventDefault();
      e3.stopPropagation();
    }
  });

  delegate(document, 'click', '.pop-out-toggle', target => {
    const popout = target.closest('.popper');
    popout.content = popout.querySelector('.pop-out');

    target.addEventListener('click', event => {
      event.stopPropagation(); // FIXME
      event.preventDefault();
      Popout.toggle(popout);
    });

    popout.addEventListener('mousedown', event => {
      event.stopPropagation(); // FIXME
    });

    Popout.toggle(popout);
  });

  document.addEventListener('mousedown', () => Popout.hideAll());
});
