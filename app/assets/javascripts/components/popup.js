/**
 * Fancy pop-ups.
 */

import { createWindow } from './window';

function createPopup(ref) {
  var win = createWindow(ref);
  win.setFooter(ref.foot);
  return win;
}

export function popupConfirm(msg, title) {
  return createPopup({
    icon: 'warning',
    title: title || 'Confirm',
    content: msg,
    foot: '<button type="button" class="button-fw confirm green left" data-resolve="true">OK</button>\
           <button type="button" class="button-fw cancel blue right" data-resolve="false">Cancel</button>'
  });
}

export function popupError(msg, title) {
  console.error(msg);
  return createPopup({
    icon: 'warning',
    title: title || 'Error',
    content: msg,
    foot: '<button type="button" class="button-fw confirm green left" data-resolve="true">OK</button>'
  });
}
