import { bindEvent } from '../../jslim/events';
import { all } from '../../jslim/dom';

function totalOuterWidth(element) {
  const style = window.getComputedStyle(element);
  return element.getBoundingClientRect().width
    + parseFloat(style.marginLeft)
    + parseFloat(style.marginRight);
}

function getPreferredColumnCount(ul) {
  const firstCell = ul.firstElementChild;

  if (!firstCell) {
    return 0;
  }
  
  const containerWidth = ul.clientWidth;

  const cellWidth = totalOuterWidth(firstCell);

  if (ul.classList.contains('latest')) {
    return Math.ceil(containerWidth / cellWidth);
  }

  return Math.floor(containerWidth / cellWidth);
}

export function alignLists() {
  all('ul.horizontal li.virtual:not(.keep)', li => li.parentNode.removeChild(li));

  requestAnimationFrame(() => {
    calculateAlignments();
    setTimeout(calculateAlignments, 500);
  });
}

function calculateAlignments() {
  all('ul.horizontal li.virtual:not(.keep)', li => li.parentNode.removeChild(li));
  all('ul.horizontal:not([data-aligned="false"])', ul => {
    const columnCount = getPreferredColumnCount(ul);
    if (!columnCount) {
      return;
    }

    let itemsLastRow = ul.children.length;
    if (!ul.classList.contains('latest')) {
      itemsLastRow %= columnCount;
    }

    if (!itemsLastRow) {
      return;
    }

    while (itemsLastRow++ < columnCount) {
      ul.appendChild(ul.firstElementChild.cloneNode());
      ul.lastChild.classList.add('virtual');
      ul.lastChild.classList.remove('keep');
    }
  });
}

bindEvent(document, 'pagechange', alignLists);
