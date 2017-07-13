/**
 * Windows
 */

import { Key } from '../utils/misc';

const windowHtml = `
<div class="popup-container focus dialog">
  <div class="fade"></div>
  <div class="popup">
    <h1 class="popup-header">
      <i class="fa {icon}"></i>
      {title}
      <a class="close" data-resolve="false"></a>
    </h1>
    <div class="content">
      <div class="message_content">{content}</div>
      <div class="foot center">
        {foot}
      </div>
    </div>
  </div>
</div>
`;

let win, overlay;

export function closeWindow() {
  document.body.removeChild(overlay);
  win = overlay = null;
}

export function createWindow({icon, title, content, foot}) {
  if (win) throw new Error('Cannot have multiple windows open at once');

  const html = windowHtml
    .replace(/{icon}/, icon)
    .replace(/{title}/, title)
    .replace(/{content}/, content)
    .replace(/{foot}/, foot);

  document.body.insertAdjacentHTML('beforeend', html);

  overlay = document.querySelector('.popup-container');
  win     = document.querySelector('.popup');

  return [ overlay, win ];
}

export function handleEvents(overlay, win) {
  return new Promise(resolve => {
    function resolveWith(val) {
      closeWindow();
      resolve(val);
    }

    win.addEventListener('click', e => {
      if (e.target.matches('[data-resolve]')) resolveWith(e.target.dataset.resolve === 'true');

      // Prevents the below listener from firing if the click was in the box
      e.stopPropagation();
    });

    overlay.addEventListener('click', () => resolveWith(false));
    overlay.addEventListener('keydown', e => {
      if (e.which === Key.ENTER) resolveWith(true);
      if (e.which === Key.ESC) resolveWith(false);
    });
  });
}
