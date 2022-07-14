import { offset } from '../jslim/dom';
import { addDelegatedEvent, bindEvent, halt, dispatchEvent } from '../jslim/events';


addDelegatedEvent(document, 'contextmenu', '.context-menu-parent:not([data-nocontext="true"])', (ev, sender) => {
  const dom = sender.querySelector('.contextmenu');
  const x = ev.clientX, y = ev.clientY;

  ev.preventDefault();

  if (dom.dataset.initialized !== 'true') {
    dom.dataset.initialized = true;
    addDelegatedEvent(dom, 'click', '[data-option]', (e, target) => {
      halt(e);

      const item = dom.items ? dom.items[target.dataset.option] : null;
      if (item) {
        item.onChange = value => {
          target.dataset.value = value;
        };
        item.setter(item.incrementer(item.getter()));
      }
    });

    dispatchEvent('contextmenu:shown', {
      buildMenu(items) {
        dom.items = items;
        performShow(x, y, sender, dom);
      }
    }, dom);
  } else {
    performShow(x, y, sender, dom);
  }
});

bindEvent(window, 'resize', hideAll);
bindEvent(window, 'blur', hideAll);
bindEvent(document, 'click', ev => {
  if (ev.button === 0) hideAll();
});

function performShow(x, y, container, dom) {
  dom.querySelectorAll('[data-option]').forEach(option => {
    const item = dom.items ? dom.items[option.dataset.option] : null;
    if (item) {
      item.onChange = value => {
        option.dataset.value = value;
      };
      item.setter(item.getter());
    }
  });

  if (x + dom.offsetWidth >= document.body.clientWidth) {
    x = document.body.clientWidth - dom.offsetWidth;
  }
  if (y + dom.offsetHeight >= document.body.clientHeight) {
    y = document.body.clientHeight - dom.offsetHeight;
  }

  const off = offset(container);
  x += document.scrollingElement.scrollLeft - off.left;
  y += document.scrollingElement.scrollTop - off.top;

  dom.style.top = `${y}px`;
  dom.style.left = `${x}px`;
  dom.classList.remove('hidden');
  getFader(dom).classList.remove('hidden');
}

function getFader(dom) {
  let fader = dom.parentNode.querySelector('.contextmenu-fader');
  if (!fader) {
    dom.insertAdjacentHTML('beforebegin', '<div class="contextmenu-fader hidden"></div>');
    fader = dom.parentNode.querySelector('.contextmenu-fader');
    fader.addEventListener('click', ev => {
      if (ev.which !== 1) return;
      dom.classList.add('hidden');
      fader.classList.add('hidden');
      halt(ev);
    });
  }
  return fader;
}

function hideAll() {
  document.querySelectorAll('.contextmenu, .contextmenu-fader').forEach(p => p.classList.add('hidden'));
}
