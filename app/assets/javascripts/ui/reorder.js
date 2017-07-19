import { ajax } from '../utils/ajax';
import { paginator } from '../components/paginator';
import { jSlim } from '../utils/jslim';

let floater = null;

// For utils
function once(node, type, listener) {
  function wrapper() {
    node.removeEventListener(type, wrapper);
    return listener.apply(this, arguments);
  }
  node.addEventListener(type, wrapper);
}

function moveFloater(e) {
  floater.style.top = e.pageY - jSlim.offset(floater.parentNode).top + 'px';
}

function reorder(target, id, index) {
  ajax.post('update/' + target, {
    id: id, index: index
  }).text(function() { });
}

function grab(target, container, item) {
  const originalIndex = parseInt(item.dataset.index, 10);

  container.classList.add('ordering');
  let grabbed = container.querySelector('.grabbed');
  if (grabbed) item.classList.remove('grabbed');

  floater = item.cloneNode(true);
  item.classList.add('grabbed');
  container.appendChild(floater);

  const srcChilds = item.children;
  const dstChilds = floater.children;

  for (let i = 0; i < srcChilds.length; ++i) {
    dstChilds[i].style.width = srcChilds[i].clientWidth + 'px';
  }

  floater.classList.add('floater');
  floater.style.top = jSlim.offset(item).top + 'px';

  const notFloating = [].filter.call(container.children, c => c.matches(':not(.floater)'));

  function childMouseover(event) {
    const child = event.currentTarget;
    let index = parseInt(child.dataset.index, 10);

    child.insertAdjacentElement('afterend', item);
    if (index <= originalIndex) ++index;
    item.dataset.index = index;
  }

  once(document, 'mouseup', e => {
    floater.parentNode.removeChild(floater);
    floater = null;
    reorder(target, item.dataset.id, item.dataset.index);
    container.classList.remove('ordering');
    grabbed = container.querySelector('.grabbed');
    if (grabbed) item.classList.remove('grabbed');

    notFloating.forEach(el => el.removeEventListener('mouseover', childMouseover));

    document.removeEventListener('mousemove', moveFloater);
    for (let i = 0; i < container.children.length; ++i) {
      container.children[i].dataset.index = i;
    }

    e.preventDefault();
    e.stopPropagation();
  });

  document.addEventListener('mousemove', moveFloater);
  notFloating.forEach(el => el.addEventListener('mouseover', childMouseover));
}

jSlim.ready(function() {
  jSlim.all('.reorderable', el => {
    const target = el.dataset.target;
    const handles = [].slice.call(el.querySelectorAll('.handle'));
    
    handles.forEach(handle => {
      const grabber = () => grab(target, el, handle.parentNode);
      
      handle.addEventListener('mousedown', e => {
        once(document, 'mousemove', grabber);
        e.preventDefault();
        e.stopPropagation();
      });
      
      handle.addEventListener('mouseup', () => {
        document.removeEventListener('mousemove', grabber);
      });
    });
  });
});

jSlim.on(document, 'click', '.removeable .remove', function(e) {
  var me = this.closest('.removeable');
  
  if (me.classList.contains('repaintable')) {
    return ajax.post('delete/' + me.dataset.target, {
      id: me.dataset.id
    }).json(function(json) {
      paginator.repaint(me.closest('.paginator'), json);
    });
  }
  
  if (me.dataset.target) {
    ajax.post('delete/' + me.dataset.target, {
      id: me.dataset.id
    }).text(function() {
      me.parentNode.removeChild(me);
    });
  } else {
    me.parentNode.removeChild(me);
  }
  e.preventDefault();
  e.stopPropagation();
});
