/**
 * Windows
 */
import { addDelegatedEvent, bindEvent } from '../jslim/events';
import { nodeFromHTML } from '../jslim/dom';
import { Key } from '../utils/key';
import { moveToCenter } from '../ui/draggable';

function createPopupContent(params) {
  return nodeFromHTML(`<div class="popup-container focus transitional hidden ui-draggable error-shakeable">
    <div class="popup">
      <h1 class="popup-header drag-handle">
        <i class="fa fa-${params.icon}"></i>
        ${params.title}
        <a class="close" data-resolve="false">
          <i class="fa fa-fw fa-close"></i>
        </a>
      </h1>
      <div class="content">
        <div class="message_content">${params.content}</div>
        <div class="foot center${params.foot ? '' : ' hidden'}">${params.foot || ''}</div>
      </div>
    </div>
  </div>`);
}

function focus(dom) {
  document.querySelectorAll('.popup-container.focus').forEach(a => a.classList.remove('focus'));
  requestAnimationFrame(() => {
    dom.classList.remove('hidden');
    dom.classList.add('focus');
  });
}

function resolve(win, result) {
  win.dom.classList.add('hidden');

  if (win.dom.classList.contains('focus'))  {
    const others = document.querySelectorAll('.popup-container:not(.hidden)');

    if (others.length) {
      focus(others[others.length - 1]);
    }
  }

  setTimeout(() => win.dom.remove(), 500);

  if (result && win.accept) {
    win.accept();
  }
}

function PopupWindow(dom) {
  this.dom = createPopupContent(dom);
  this.dom.windowObj = this;
  this.content = this.dom.querySelector('.content');
  this.dom.addEventListener('resolve', e => {
    resolve(this, e.detail.data.resolution === 'true');
  });
  this.show();
}
PopupWindow.prototype = {
  show() {
    this.dom.classList.add('hidden');
    document.querySelector('.fades').insertAdjacentElement('beforebegin', this.dom);
    requestAnimationFrame(() => {
      focus(this.dom);
      moveToCenter(this.dom);
    });
  },
  setContent(content) {
    this.content.innerHTML = content;
  },
  setOnAccept(func) {
    this.accept = func;
  }
}

export function createWindow(params) {
  return new PopupWindow(params);
}

bindEvent(document, 'keydown', e => {
  const activeWindow = document.querySelector('.popup-container.focus');
  if (!activeWindow) return;
  if (e.which === Key.ESC) resolve(activeWindow.windowObj, false);
  if (e.which === Key.ENTER) {
    e.preventDefault(); // hitting enter triggers the link again. Let's stop that.
    const accept = activeWindow.querySelector('.confirm');

    if (accept) {
      accept.click();
    } else {
      resolve(activeWindow.windowObj, true);
    }
  }
});
