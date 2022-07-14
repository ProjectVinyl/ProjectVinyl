import { offset } from '../jslim/dom';
import { addDelegatedEvent, bindEvent, halt, dispatchEvent } from '../jslim/events';

function buildMenu(dom, items) {
  const keys = Object.keys(items);

  keys.forEach(key => {
    const label = dom.querySelector(`[data-option="${key}"] .value`);
    if (label) {
      items[key].initial(newValue => {
        label.innerHTML = s === true ? '<i class="fa fa-check"></i>' : (s || '');
      });
    }
  });
  
  dom.querySelectorAll('[data-option]').forEach(option => {
    const item = items[option.dataset.option];
    option.dataset.value = item ? item.initial : '';
  });

  addDelegatedEvent(dom, 'click', '[data-option]', (e, target) => {
    const item = items[target.dataset.option];
    if (item) {
      target.dataset.value = item.callback();
    }
    halt(e);
  });
}

function performShow(x, y, container, dom) {
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

export function hideAll() {
  document.querySelectorAll('.contextmenu, .contextmenu-fader').forEach(p => p.classList.add('hidden'));
}

addDelegatedEvent(document, 'contextmenu', '.context-menu-parent:not([data-nocontext="true"])', (ev, sender) => {
  const dom = sender.querySelector('.contextmenu');
  const x = ev.clientX;
  const y = ev.clientY;

  ev.preventDefault();

  if (dom.dataset.initialized !== 'true') {
    dom.dataset.initialized = true;
    dispatchEvent('contextmenu:shown', {
      buildMenu(items) {
        buildMenu(dom, items);
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
