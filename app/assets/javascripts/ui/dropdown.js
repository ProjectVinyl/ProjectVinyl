import { all, offset } from '../jslim/dom';
import { addDelegatedEvent, halt } from '../jslim/events';

addDelegatedEvent(document, 'click', '.popper .pop-out-toggle, .popper.pop-out-toggle', (e, target) => {
  if (e.which != 1) return;
  e.preventDefault();
  
  target = target.closest('.popper');
  target.classList.toggle('pop-out-shown');
  if (!target.classList.contains('pop-out-shown')) return;
  
  const content = target.querySelector('.pop-out');
  const left = offset(content).left;
  
  target.classList.toggle('pop-left', left + content.offsetWidth > document.documentElement.offsetWidth);
  target.classList.toggle('pop-right', left < 0);
});

document.addEventListener('mousedown', () => all('.pop-out-shown:not(:hover)', a => {
	sender.classList.remove('pop-out-shown');
}));

addDelegatedEvent(document, 'touchstart', '.drop-down-holder:not(.hover), .mobile-touch-toggle:not(.hover)', (e, target) => {
  e.preventDefault();
  target.classList.add('hover');
  
  // ffs https://www.chromestatus.com/features/5093566007214080
  ['touchstart', 'touchmove'].forEach(t => {
    target.addEventListener(t, clos, { passive: false });
    document.addEventListener(t, clos, { passive: false });
  });
  
  function clos(e) {
    if (e.target.closest('a')) return; // Links should only be triggered on touch when the drop-down is already open
    halt(e);
    
    target.classList.remove('hover');
    
    ['touchstart', 'touchmove'].forEach(t => {
      target.removeEventListener(t, clos);
      document.removeEventListener(t, clos);
    });
  }
}, { passive: false });
