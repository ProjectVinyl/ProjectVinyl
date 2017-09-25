import { ajax } from '../utils/ajax';
import { once, addDelegatedEvent } from '../jslim/events';
import { offset, each } from '../jslim/dom';

function reorder(container, item) {
  each(container.children, (a, i) => a.dataset.index = (i - 1));
  ajax.patch(`${container.dataset.target}/${item.dataset.id}`, { index: item.dataset.index }).text(e => e);
}

function grab(container, item) {
  const originalIndex = parseInt(item.dataset.index);
  
  container.classList.add('ordering');
  
  const floater = item.cloneNode(true);
  floater.classList.add('floater');
  floater.style.top = `${offset(item).top}px`;
  each(item.children, (a, i) => {
    floater.children[i].style.width = `${a.clientWidth}px`;
  });
  item.classList.add('grabbed');
  container.appendChild(floater);
  
  const notFloating = Array.prototype.filter.call(container.children, c => !c.classList.contains('.floater'));
  
  function childMouseover() {
    this.insertAdjacentElement('afterend', item);
  }
  
  function moveFloater(e) {
    floater.style.top = `${e.pageY - offset(container).top}px`;
  }
  
  document.addEventListener('mousemove', moveFloater);
  notFloating.forEach(el => el.addEventListener('mouseover', childMouseover));
  once(document, 'mouseup', e => {
    e.preventDefault();
    
    container.classList.remove('ordering');
    item.classList.remove('grabbed');
    
    notFloating.forEach(el => el.removeEventListener('mouseover', childMouseover));
    document.removeEventListener('mousemove', moveFloater);
    floater.parentNode.removeChild(floater);
    
    reorder(container, item);
  });
}

addDelegatedEvent(document, 'mousedown', '.reorderable .handle', (e, handle) => {
  e.preventDefault();
  
  document.addEventListener('mousemove', grabber);
  document.addEventListener('mouseup', cancelAll);
  document.addEventListener('blur', cancelAll);
  
  function grabber() {
    cancelAll();
    grab(handle.closest('.reorderable'), handle.parentNode);
  }
  
  function cancelAll() {
    document.removeEventListener('mousemove', grabber);
    document.removeEventListener('mouseup', cancelAll);
    document.removeEventListener('blur', cancelAll);
  }
});
