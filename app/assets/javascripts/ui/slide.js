import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';

export function slideOut(holder) {
  const h = holder.querySelector('.group.active').offsetHeight;
  holder.style.minHeight = `${h}px`;
  holder.style.maxHeight = `%{h + 10}px`;
	const toggleOn = !holder.classList.contains('shown');
  jSlim.all('.slideout.shown', el => el.classList.remove('shown'));
  if (toggleOn) holder.classList.add('shown');
  return holder;
}

export function slideAcross(me, direction) {
  const form = me.closest('.slide-group');
  
  const to = form.querySelector('.group[data-stage=' + me.dataset.to + ']');
  if (!to) return;
  
  form.dataset.offset = (parseInt(form.dataset.offset) || 0) + direction;
  
  const from = form.querySelector('.active');
  if (from) {
    from.classList.remove('active');
    if (direction > 0) {
      from.parentNode.insertBefore(to, from.nextSibling);
    } else {
      from.parentNode.insertBefore(to, from);
    }
  }
  
  to.classList.add('active');
  form.classList.add('animating');
  
  requestAnimationFrame(() => {
    form.style.maxHeight = form.style.minHeight = to.offsetHeight + 'px';
    jSlim.all(form, '.group', el => el.style.transform = `translate(-${100 * form.dataset.offset}%,0)`);
    setTimeout(() => {
      form.classList.remove('animating');
      form.style.maxHeight = '';
    }, 500);
  });
}

jSlim.on(document, 'click', '.slider-toggle', (e, target) => {
  if (e.button !== 0) return;
  const holder = document.querySelector(target.dataset.target);
  if (target.classList.contains('loadable') && !target.classList.contains('loaded')) {
    target.classList.add('loaded');
    ajax.get(target.dataset.url).json(json => {
      holder.innerHTML = json.content;
      slideOut(holder);
    });
  } else {
    slideOut(holder);
  }
  e.preventDefault();
});

jSlim.on(document, 'click', '.slide-holder .goto.slide-right', (e, target) => {
  if (e.button === 0) slideAcross(target, 1);
});

jSlim.on(document, 'click', '.slide-holder .goto.slide-left', (e, target) => {
  if (e.button === 0) slideAcross(target, -1);
});
