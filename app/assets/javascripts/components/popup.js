/**
 * Fancy pop-ups.
 */

import { createWindow, closeWindow } from './window';

function createPopup(ref) {
  return createWindow(ref);
}

export function popupConfirm(msg, title) {
  return createPopup({
    icon: 'fa-warning',
    title: title || 'Confirm',
    content: msg,
    foot: '<button type="button" class="button-fw confirm green left" data-resolve="true">OK</button>\
           <button type="button" class="button-fw cancel blue right" data-resolve="false">Cancel</button>'
  });
}

export function popupError(msg, title) {
  return createPopup({
    icon: 'fa-warning',
    title: title || 'Error',
    content: msg,
    foot: '<button type="button" class="button-fw confirm green left" data-resolve="true">OK</button>'
  });
}
