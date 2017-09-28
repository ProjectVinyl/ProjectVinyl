import { all, offset } from '../jslim/dom';

export function ContextMenu(dom, container) {
  this.dom = dom;
  this.container = container || document.body;
  this.container.addEventListener('contextmenu', e => this.show(e));
}
ContextMenu.prototype = {
  addItem: function(title, initial, callback) {
    this.dom.insertAdjacentHTML('beforeend', `<li><div class="label">${title}</div><div class="value"></div></li>`);
    this.dom.lastChild.addEventListener('click', () => callback(val));
    
    const item = this.dom.lastChild.querySelector('.value');
    
    function val(s) {
      item.innerHTML = s === true ? '<i class="fa fa-check"></i>' : (s || '');
      return s;
    }
    
    val(initial);
  },
  show: function(ev) {
    ev.preventDefault();
    
    let x = ev.clientX, y = ev.clientY;
    
    if (x + this.dom.offsetWidth >= document.body.clientWidth) {
      x = document.body.clientWidth - this.dom.offsetWidth;
    }
    if (y + this.dom.offsetHeight >= document.body.clientHeight) {
      y = document.body.clientHeight - this.dom.offsetHeight;
    }
    
    const off = offset(this.container);
    x += document.scrollingElement.scrollLeft - off.left;
    y += document.scrollingElement.scrollTop - off.top;
    
    this.dom.style.top = `${y}px`;
    this.dom.style.left = `${x}px`;
    this.dom.classList.remove('hidden');
  },
  hide: function(ev) {
    if (ev.which !== 1 || this.dom.classList.contains('hidden')) return;
    this.dom.classList.add('hidden');
    return true;
  }
};

function hideAll() {
  all('.contextmenu', p => p.classList.add('hidden'));
}

window.addEventListener('resize', hideAll);
window.addEventListener('blur', hideAll);
document.addEventListener('click', ev => {
  if (ev.button === 0) hideAll();
});
