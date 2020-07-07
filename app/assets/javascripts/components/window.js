/**
 * Windows
 */
import { addDelegatedEvent, bindEvent } from '../jslim/events';
import { all, nodeFromHTML } from '../jslim/dom';
import { Key } from '../utils/key';
import { initDraggable, move } from './draggable';

function createPopupContent(params) {
  return nodeFromHTML(`<div class="popup-container focus transitional hidden ui-draggable">
    <div class="popup">
      <h1 class="popup-header">
        <i class="fa fa-${params.icon}"></i> ${params.title} <a class="close" data-resolve="false"></a>
      </h1>
      <div class="content">
        <div class="message_content">${params.content}</div>
        <div class="foot center${params.foot ? '' : ' hidden'}">${params.foot || ''}</div>
      </div>
    </div>
  </div>`);
}

function focus(dom) {
  all(document, '.popup-container.focus', a => a.classList.remove('focus'));
  dom.classList.remove('hidden');
  dom.classList.add('focus');
}

function resolve(win, result) {
  win.dom.classList.add('hidden');
  if (win.dom.classList.contains('focus'))  {
    const others = document.querySelectorAll('.popup-container:not(.hidden)');
    if (others.length) {
      focus(others[others.length - 1]);
    }
  }
  setTimeout(() => win.dom.parentNode.removeChild(win.dom), 500);
  if (result && win.accept) win.accept();
}

function PopupWindow(dom) {
  this.dom = createPopupContent(dom);
  this.dom.windowObj = this;
  this.content = this.dom.querySelector('.content');
  
  addDelegatedEvent(this.dom, 'click', '[data-resolve]', (e, target) => {
    resolve(this, target.dataset.resolve === 'true');
  });
  initDraggable(this.dom, 'h1.popup-header');
  this.show();
}
PopupWindow.prototype = {
  show() {
    document.querySelector('.fades').insertAdjacentElement('beforebegin', this.dom);
    requestAnimationFrame(() => {
      focus(this.dom);
      this.center();
    });
  },
  setContent(content) {
    this.content.innerHTML = content;
  },
  setOnAccept(func) {
    this.accept = func;
  },
  center() {
    const x = (document.body.offsetWidth - this.dom.offsetWidth) / 2;
    const y = (document.body.offsetHeight - this.dom.offsetHeight) / 2;
    move(this.dom, x, y);
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
