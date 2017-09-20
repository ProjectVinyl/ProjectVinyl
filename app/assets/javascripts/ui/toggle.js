import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';

function toggle(e, sender, options, callback) {
	e.preventDefault();
  const data = {};
  if (sender.dataset.item) data.item = sender.dataset.item;
  if (sender.dataset.with) data.extra = document.querySelector(sender.dataset.with).value;
  
  ajax.put(`${options.dataset.target}/${options.dataset.id}/${options.dataset.action}`, data).json(json => callback(json, options));
}

function updateCheck(element, state) {
  const check = element.dataset.checkedIcon || 'check';
  const uncheck = element.dataset.uncheckedIcon;
  element.querySelector('.icon').innerHTML = state ? `<i class="fa fa-${state}"></i>` : uncheck ? `<i class="fa fa-${uncheck}></i>` : '';
}

jSlim.on(document, 'click', '.action.toggle', (e, target) => {
  if (e.which === 1 || e.button === 0) toggle(e, target, target, json => {
    if (target.dataset.family) {
      return jSlim.all(`.action.toggle[data-family="${target.dataset.family}"][data-id="${target.dataset.id}"]`, a => {
        updateCheck(a, json[a.dataset.descriminator]);
      });
    }
    
    updateCheck(target, json.added);
    if (target.dataset.state) {
      target.closest(target.dataset.parent).classList.toggle(target.dataset.state, json.added);
    }
  });
});

jSlim.on(document, 'click', '.action.multi-toggle [data-item]', (e, target) => {
  if (e.which === 1 || e.button === 0) toggle(e, target, target.closest('.action.multi-toggle'), (json, options) => {
    jSlim.all(options, '[data-item]', a => updateCheck(a, json[a.dataset.descriminator]));
  });
});

jSlim.on(document, 'click', '.state-toggle', (e, target) => {
  if (e.which != 1 && e.button != 0) return;
  e.preventDefault();
	
	let parent = target.dataset.parent;
	parent = parent ? target.closest(parent) : target.parentNode;
	
	const state = target.dataset.state;
	parent.classList.toggle(state);
	
	const label = target.dataset[parent.classList.contains(state)];
	if (label) target.innerText = label;
	
	target.dispatchEvent(new CustomEvent('toggle', {bubbles: true}));
});
