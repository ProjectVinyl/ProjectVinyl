import { jSlim } from '../utils/jslim';

function hide(sender) {
	sender.classList.remove('pop-out-shown');
}

document.addEventListener('mousedown', () => jSlim.all('.pop-out-shown:not(:hover)', hide));
jSlim.on(document, 'click', '.popper .pop-out-toggle', (e, target) => {
  if (e.which != 1) return;
	e.preventDefault();
	
  target = target.closest('.popper');
	if (target.classList.contains('pop-out-shown')) {
		return hide(sender);
	}
	
	const content = target.querySelector('.pop-out');
	const left = jSlim.offset(content).left;
	
	target.classList.add('pop-out-shown');
	target.classList.toggle('pop-left', left + content.clientWidth > document.documentElement.clientWidth);
	target.classList.toggle('pop-right', left < 0);
});

jSlim.on(document, 'touchstart', '.drop-down-holder:not(.hover), .mobile-touch-toggle:not(.hover)', (e, target) => {
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
