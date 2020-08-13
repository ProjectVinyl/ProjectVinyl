import { ready, bindEvent } from '../jslim/events';
import { all } from '../jslim/dom';

// +1 to prevent jittering
const EXTRA_SPACE = 1;

function getTargetPage(grid, b) {
  for (const page of grid.querySelectorAll('.page')) {
    const t = page.getBoundingClientRect();

    if (t.top < b && t.bottom > b) {
      if (t.top > b - 50 && t.top < b + 50) {
        page.classList.add('full-width');
        
        continue;
      }

      return page;
    }
  }
}

function calculatePageSplit(grid, b) {
  const page = getTargetPage(grid, b);

  if (!page) {
    return;
  }

  let found;
  
  const ul = page.querySelector('ul');
  
  for (let i = 0; i < ul.children.length; i++) {
    const li = ul.children[i];

    if (!found && li.getBoundingClientRect().top >= b) {
      page.classList.add('split');
      page.insertAdjacentHTML('afterend', '<section class="page virtual"><div class="group"><ul class="horizontal latest"></ul></div></section>');
      found = page.nextSibling.querySelector('ul');
    }
    
    if (found) {
      found.appendChild(li);
    }
  }
}

function resizeGrid(grid, beside) {
  all(grid, '.page.virtual', page => {
    let prev = page.previousSibling;
    prev.classList.remove('split');
    prev = prev.querySelector('ul');
    all(page, 'li', a => prev.appendChild(a));
    page.parentNode.removeChild(page);
  });
  all(grid, '.page.full-width', page => {
    page.classList.remove('full-width');
  });
  calculatePageSplit(grid, beside.getBoundingClientRect().bottom);
}

function getPreferredColumnCount(ul) {
  let ulWidth = ul.clientWidth;
  if (!ul.firstElementChild) {
    return 0;
  }

  const style = window.getComputedStyle(ul.firstElementChild);
  
  let liWidth = ul.firstElementChild.getBoundingClientRect().width + parseFloat(style.marginLeft) + parseFloat(style.marginRight);
  
  return Math.floor(ulWidth / liWidth);
}

function alignLists() {
  all('ul.horizontal li.virtual:not(.keep)', li => li.parentNode.removeChild(li));
  
  requestAnimationFrame(() => {
    all('ul.horizontal:not([data-aligned="false"])', ul => {
      const columnCount = getPreferredColumnCount(ul);
      if (!columnCount) {
        return;
      }
      let itemsLastRow = ul.children.length % columnCount;
      if (!itemsLastRow) {
        return;
      }

      while (itemsLastRow++ < columnCount) {
        ul.appendChild(ul.firstElementChild.cloneNode());
        ul.lastChild.classList.add('virtual');
        ul.lastChild.classList.remove('keep');
      }
    });
  });
}

bindEvent(document, 'pagechange', alignLists);

ready(() => {
  const columnRight = document.querySelector('.grid-root.column-right');
  if (!columnRight) {
    alignLists();
    return bindEvent(window, 'resize', alignLists);
  }
  
  const columnLeft = document.querySelector('.grid-root.column-left');
  
  function resize() {
    alignLists();
    resizeGrid(columnLeft, columnRight);
  }
  
  bindEvent(window, 'resize', resize);
  resize();
});
