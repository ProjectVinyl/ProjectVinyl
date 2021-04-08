import { ajax } from '../utils/ajax';
import { clamp } from '../utils/math';
import { once, addDelegatedEvent } from '../jslim/events';
import { offset, each } from '../jslim/dom';
import { stopShoving, shove } from './shove';
import { scrollContext } from './reflow';
import { Key } from '../utils/key';

function saveOrdering(container, item) {
  each(container.children, (a, i) => a.dataset.index = (i - 1));
  ajax.patch(`${container.dataset.target}/${item.dataset.id}`, {
    index: item.dataset.index
  });
}

function grab(container, item, ev) {
  const originalIndex = parseInt(item.dataset.index);
  let dropped;
  
  container.classList.add('ordering');

  const floater = item.cloneNode(true);
  const handle = floater.querySelector('.handle');

  floater.classList.add('floater');

  each(item.children, (a, i) => floater.children[i].style.width = `${a.clientWidth}px`);

  item.classList.add('grabbed');
  container.appendChild(floater);
  moveFloater(ev);

  const notFloating = Array.prototype.filter.call(container.children, c => !c.classList.contains('.floater'));

  function childMouseover() {
    this.insertAdjacentElement('afterend', item);
  }
  
  function moveFloater(e) {
    const topOffset = (handle.clientTop - item.clientTop) + (handle.clientHeight / 2);
    const top = e.clientY - offset(container).top - topOffset;
    floater.style.top = `${clamp(top, 0, container.clientHeight)}px`;
    
    shove(e, scrollContext(floater));
  }
  
  document.addEventListener('mousemove', moveFloater);

  notFloating.forEach(el => el.addEventListener('mouseover', childMouseover));

  function stopDragging() {
    container.classList.remove('ordering');
    item.classList.remove('grabbed');
    
    notFloating.forEach(el => el.removeEventListener('mouseover', childMouseover));
    document.removeEventListener('mousemove', moveFloater);
    floater.parentNode.removeChild(floater);
    
    stopShoving();
  }

  once(document, 'keyup', e => {
    if (dropped || e.which != Key.ESC) {
      return;
    }
    dropped = true;
    e.preventDefault();
    stopDragging();
    
    insertInto(container, originalIndex, item, 'Element');
  });
  once(document, 'mouseup', e => {
    if (dropped) {
      return;
    }
    dropped = true;
    e.preventDefault();
    stopDragging();

    saveOrdering(container, item);
  });
}

export function insert(parentId, index, content, type) {
  const container = document.querySelector(parentId);
  if (container) {
    insertInto(container, index, content, type);
  } else {
    console.error("Unknown parent " + parentId);
  }
}

function insertInto(container, index, content, type) {
  const node = container.querySelector(`.removeable[data-index="${index - 1}"]`) || container.querySelector('.bump');
  if (node) {
    type = type || 'HTML';
    node['insertAdjacent' + type]('afterend', content);
    each(container.children, (a, i) => a.dataset.index = (i - 1));
  } else {
    console.error("No insert position found");
  }
}

addDelegatedEvent(document, 'mousedown', '.reorderable .handle', (e, handle) => {
  e.preventDefault();
  
  document.addEventListener('mousemove', grabber);
  document.addEventListener('mouseup', cancelAll);
  document.addEventListener('blur', cancelAll);
  
  function grabber(e) {
    cancelAll();
    grab(handle.closest('.reorderable'), handle.closest('.removeable'), e);
  }
  
  function cancelAll() {
    document.removeEventListener('mousemove', grabber);
    document.removeEventListener('mouseup', cancelAll);
    document.removeEventListener('blur', cancelAll);
  }
});
