/**
 * Windows
 */
import { addDelegatedEvent } from '../jslim/events';
import { all, nodeFromHTML } from '../jslim/dom';
import { Key } from '../utils/misc';
import { initDraggable, move } from './draggable';

function createPopupContent(params) {
	return nodeFromHTML(`<div class="popup-container focus transitional hidden ui-draggable">
		<div class="popup">
			<h1 class="popup-header">
				<i class="fa fa-${params.icon}"></i>
				${params.title}
				<a class="close" data-resolve="false"></a>
			</h1>
			<div class="content">
				<div class="message_content">${params.content}</div>
				<div class="foot center hidden"></div>
			</div>
		</div>
	</div>`);
}

function PopupWindow(dom) {
  this.dom = dom;
  this.dom.windowObj = this;
  this.content = this.dom.querySelector('.content');
  this.foot = this.content.querySelector('.foot');
}
PopupWindow.prototype = {
  show: function() {
    document.querySelector('.fades').insertAdjacentElement('beforebegin', this.dom);
    requestAnimationFrame(() => {
      this.focus();
      centerWindow(this);
    });
  },
  close: function() {
    this.dom.classList.add('hidden');
    if (this.dom.classList.contains('focus'))  {
      var others = document.querySelectorAll('.popup-container:not(.hidden)');
      if (others.length) {
        others[others.length - 1].windowObj.focus();
      }
    }
    setTimeout(() => {
      this.dom.parentNode.removeChild(this.dom);
    }, 500);
  },
  focus: function() {
    all(document, '.popup-container.focus', a => a.classList.remove('focus'));
    this.dom.classList.remove('hidden');
    this.dom.classList.add('focus');
  },
  setContent: function(content) {
    this.content.innerHTML = content;
  },
  setFooter: function(content) {
    this.foot.classList.remove('hidden');
    this.foot.innerHTML = content;
  },
  setOnAccept: function(func) {
    this.accept = func;
  }
}

function resolveWith(win, result) {
  win.close();
  if (result && win.accept) win.accept();
}

function handleEvents(win) {
  addDelegatedEvent(win.dom, 'click', '[data-resolve]', e => {
    if (e.target.matches('[data-resolve]')) {
      resolveWith(win, e.target.dataset.resolve === 'true');
    }
  });
  initDraggable(win.dom, 'h1.popup-header');
}

document.addEventListener('keydown', e => {
	const activeWindow = document.querySelector('.popup-container.focus');
	if (!activeWindow) return;
	if (e.which === Key.ESC) resolveWith(activeWindow.windowObj, false);
	if (e.which === Key.ENTER) {
		const accept = activeWindow.querySelector('.confirm');
		if (accept) {
			accept.dispatchEvent(new MouseEvent('click'));
		} else {
			resolveWith(activeWindow.windowObj, true);
		}
		e.preventDefault(); // hitting enter triggers the link again, let's stop that.
	}
});

export function createWindow(params) {
  const win = new PopupWindow(createPopupContent(params));
  handleEvents(win);
  win.show();
  return win;
}

export function centerWindow(win) {
  const x = (document.body.offsetWidth - win.dom.offsetWidth) / 2;
  const y = (document.body.offsetHeight - win.dom.offsetHeight) / 2;

  move(win.dom, x, y);
}
