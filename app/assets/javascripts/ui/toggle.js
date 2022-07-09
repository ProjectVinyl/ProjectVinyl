import { ajaxPut } from '../utils/ajax';
import { addDelegatedEvent } from '../jslim/events';

function toggle(e, sender, options, callback) {
  const data = {};
  if (sender.dataset.item) data.item = sender.dataset.item;
  if (sender.dataset.with) data.extra = document.querySelector(sender.dataset.with).value;
  
  let path = options.dataset.target;
  if (options.dataset.id) path += `/${options.dataset.id}`;
  if (options.dataset.action) path += `/${options.dataset.action}`;
  
  const loadingIcon = sender.dataset.loadingIcon;
  if (loadingIcon) {
    updateIcon(sender, loadingIcon);
  }

  ajaxPut(path, data).json(json => callback(json, options));
}

function getIcon(element, state) {
  return state ? (element.dataset.checkedIcon || 'check') : (element.dataset.uncheckedIcon || '');
}

function getTitle(element, state) {
  return state ? (element.dataset.checkedTitle || '') : (element.dataset.uncheckedTitle || '');
}

function updateCheck(element, state) {
  element.title = getTitle(element, state);
  updateIcon(element, getIcon(element, state));
}

function updateIcon(element, icon) {
  element.querySelector('.icon').innerHTML = icon.length ? `<i class="fa fa-${icon}"></i>` : '';
}

addDelegatedEvent(document, 'click', '.action.toggle', (e, target) => {
  if (e.which === 1 || e.button === 0) toggle(e, target, target, json => {
    if (target.dataset.family) {
      return document.querySelectorAll(`.action.toggle[data-family="${target.dataset.family}"][data-id="${target.dataset.id}"]`).forEach(a => {
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
    options.querySelectorAll('[data-item]').forEach(a => updateCheck(a, json[a.dataset.descriminator]));
  });
});
