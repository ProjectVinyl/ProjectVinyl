import { all, offset } from '../jslim/dom';
import { addDelegatedEvent, halt, bindEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', '.popper .pop-out-toggle, .popper.pop-out-toggle', (e, target) => {
  if (e.which != 1) return;
  e.preventDefault();

  target = target.closest('.popper');
  target.classList.toggle('pop-out-shown');
  if (!target.classList.contains('pop-out-shown')) return;

  const content = target.querySelector('.pop-out');

  target.classList.remove('pop-left', 'pop-right', 'pop-center');

  requestAnimationFrame(() => {
    const left = offset(content).left;
    const hitRight = left + content.offsetWidth > document.documentElement.offsetWidth;
    const hitLeft = left < 0;

    const parent = content.parentNode;
    const parentLeft = offset(content.parentNode).left;

    const fallRightWouldOutFlow = parentLeft + content.offsetWidth > document.documentElement.offsetWidth;
    const fallLeftWouldOutFlow = (parentLeft + parent.offsetWidth - content.offsetWidth) < 0;

    if (hitRight || hitLeft) {
      target.classList.toggle('pop-left', hitRight && !fallRightWouldOutFlow);
      target.classList.toggle('pop-right', hitLeft && !fallLeftWouldOutFlow);
      target.classList.toggle('pop-center', fallLeftWouldOutFlow && fallRightWouldOutFlow);
    }
  });
});

bindEvent(document, 'mouseup', () => all('.pop-out-shown', a => {
  if (!a.querySelector('.action.toggle:hover')) a.classList.remove('pop-out-shown');
}));
