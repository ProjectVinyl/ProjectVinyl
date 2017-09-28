/**
 * Fancy pop-ups.
 */
import { createWindow } from './window';

export function popupConfirm(msg, title) {
  return createWindow({
    icon: 'warning',
    title: title || 'Confirm',
    content: msg,
    foot: '<button type="button" class="button-fw confirm green left" data-resolve="true">OK</button>\
           <button type="button" class="button-fw cancel blue right" data-resolve="false">Cancel</button>'
  });
}

export function popupError(msg, title) {
  console.error(msg);
  return createWindow({
    icon: 'warning',
    title: title || 'Error',
    content: msg,
    foot: '<button type="button" class="button-fw confirm green left" data-resolve="true">OK</button>'
  });
}
