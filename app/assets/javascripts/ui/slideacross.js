import { addDelegatedEvent } from '../jslim/events';
import { checkFormPrerequisits } from '../utils/input_validation';

function slideAcross(me, direction) {
  const form = me.closest('.slide-group');
  
  const to = form.querySelector(`.group[data-stage=${me.dataset.to}]`);
  if (!to) return;
  
  form.dataset.offset = (parseInt(form.dataset.offset) || 0) + direction;
  
  const from = form.querySelector('.active');
  if (from) {
    from.classList.remove('active');
    from.insertAdjacentElement(direction > 0 ? 'afterend' : 'beforebegin', to);
  }
  
  to.classList.add('active');
  form.classList.add('animating');
  
  requestAnimationFrame(() => {
    form.style.maxHeight = form.style.minHeight = `${to.offsetHeight}px`;
    form.querySelectorAll('.group').forEach(el => el.style.transform = `translate(-${100 * form.dataset.offset}%,0)`);
    setTimeout(() => {
      form.classList.remove('animating');
      form.style.maxHeight = '';
    }, 500);
  });
}

addDelegatedEvent(document, 'click', '.slide-holder form input[data-to]', (e, target) => {
  if (e.button !== 0 || e.defaultPrevented) return;
  if (!checkFormPrerequisits(target.closest('.group'))) return;
  const required = target.closest('.group').querySelectorAll('input[data-required]');
  slideAcross(target, 1);
});

addDelegatedEvent(document, 'click', '.slide-holder .goto.slide-right', (e, target) => {
  if (e.button !== 0 || e.defaultPrevented) return;
  if (target.closest('form') && !checkFormPrerequisits(target.closest('.group'))) return; 
  slideAcross(target, 1);
});

addDelegatedEvent(document, 'click', '.slide-holder .goto.slide-left', (e, target) => {
  if (e.button === 0 || e.defaultPrevented) slideAcross(target, -1);
});
