import { all, offset } from '../jslim/dom';
import { addDelegatedEvent } from '../jslim/events';

function hide(sender) {
	sender.classList.remove('pop-out-shown');
}

document.addEventListener('mousedown', () => all('.pop-out-shown:not(:hover)', hide));
addDelegatedEvent(document, 'click', '.pop-out-toggle', (e, target) => {
  if (e.which != 1) return;
	
  target = target.closest('.popper');
	if (!target) return;
	e.preventDefault();
	if (target.classList.contains('pop-out-shown')) {
		return hide(target);
	}
	
	const content = target.querySelector('.pop-out');
	const left = offset(content).left;
	
	target.classList.add('pop-out-shown');
	target.classList.toggle('pop-left', left + content.clientWidth > document.documentElement.clientWidth);
	target.classList.toggle('pop-right', left < 0);
});

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
    
    target.classList.remove('hover');
    
    ['touchstart', 'touchmove'].forEach(t => {
      target.removeEventListener(t, clos);
      document.removeEventListener(t, clos);
    });
    
    e.preventDefault();
    e.stopPropagation();
  }
}, { passive: false });
