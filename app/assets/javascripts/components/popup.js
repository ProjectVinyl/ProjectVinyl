/**
 * Fancy pop-ups.
 */

import { createWindow, closeWindow, handleEvents } from './window';

const confirmButtons = `
  <button type="button" class="button-fw confirm green left" data-resolve="true">OK</button>
  <button type="button" class="button-fw cancel blue right" data-resolve="false">Cancel</button>
`;

const errorButtons = `
  <button type="button" class="button-fw confirm green left" data-resolve="true">OK</button>
`;

function createPopup(ref) {
  const win = createWindow(ref);
  return handleEvents(win);
}

export function popupConfirm(msg, title = 'Confirm') {
  return createPopup({
    icon: 'fa-warning',
    title: title,
    content: msg,
    foot: confirmButtons
  });
}

export function popupError(msg, title = 'Error') {
  closeWindow(); // kill anything already present
  return createPopup({
    icon: 'fa-warning',
    title: title,
    content: msg,
    foot: errorButtons
  });
}
