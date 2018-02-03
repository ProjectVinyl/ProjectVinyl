import { ajax } from '../utils/ajax';
import { all } from '../jslim/dom';
import { addDelegatedEvent } from '../jslim/events';

function toggle(e, sender, options, callback) {
  e.preventDefault();
  const data = {};
  if (sender.dataset.item) data.item = sender.dataset.item;
  if (sender.dataset.with) data.extra = document.querySelector(sender.dataset.with).value;
  
  ajax.put(`${options.dataset.target}/${options.dataset.id}/${options.dataset.action}`, data).json(json => callback(json, options));
}

function getIcon(element, state) {
  return state ? (element.dataset.checkedIcon || 'check') : (element.dataset.uncheckedIcon || '');
}

function updateCheck(element, state) {
  const icon = getIcon(element, state);
  element.querySelector('.icon').innerHTML = icon.length ? `<i class="fa fa-${icon}"></i>` : '';
}

addDelegatedEvent(document, 'click', '.action.toggle', (e, target) => {
  if (e.which === 1 || e.button === 0) toggle(e, target, target, json => {
    if (target.dataset.family) {
      return all(`.action.toggle[data-family="${target.dataset.family}"][data-id="${target.dataset.id}"]`, a => {
        updateCheck(a, json[a.dataset.descriminator]);
      });
    }
    
    updateCheck(target, json.added);
    if (target.dataset.state) {
      target.closest(target.dataset.parent).classList.toggle(target.dataset.state, json.added);
    }
  });
});

addDelegatedEvent(document, 'click', '.action.multi-toggle [data-item]', (e, target) => {
  if (e.which === 1 || e.button === 0) toggle(e, target, target.closest('.action.multi-toggle'), (json, options) => {
    all(options, '[data-item]', a => updateCheck(a, json[a.dataset.descriminator]));
  });
});
