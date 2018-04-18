import { ready } from '../jslim/events';
import { all } from '../jslim/dom';

// +1 to prevent jittering
const EXTRA_SPACE = 1;
const MARGIN = 60,
      COLUMN_WIDTH_SMAL = 100 + EXTRA_SPACE,
      COLUMN_WIDTH_MED = 190 + EXTRA_SPACE,
      COLUMN_WIDTH_LARGE = 215 + EXTRA_SPACE,
      SIDEBAR_WIDTH = 275,
      SIDEBAR_SPACING = 15;

function calculateNewWidth(grid, beside) {
  const docW = document.clientWidth;
  
  const maxWidth = grid.parentNode.clientWidth - SIDEBAR_WIDTH;
  const col = docW > 900 ? COLUMN_WIDTH_LARGE : docW > 700 ? COLUMN_WIDTH_MED : COLUMN_WIDTH_SMAL;
  
  let calculatedWidth = maxWidth + 1;
  let n = 10;
  
  do {
    calculatedWidth = (MARGIN * 2) + (col * n--);
  } while (calculatedWidth > maxWidth);
  
  let besideWidth = beside.parentNode.clientWidth - (calculatedWidth + SIDEBAR_SPACING);
  if (besideWidth < SIDEBAR_WIDTH) {
    calculatedWidth == besideWidth - SIDEBAR_WIDTH;
    besideWidth = SIDEBAR_WIDTH;
  }
  
  grid.style.width = `${calculatedWidth}px`;
  beside.style.width = `${besideWidth}px`;
}

function getTargetPage(grid, b) {
  for (const page of grid.querySelectorAll('.page')) {
    const t = page.getBoundingClientRect();
    if (t.top < b && t.bottom > b) return page;
  }
}

function calculatePageSplit(grid, b) {
  const page = getTargetPage(grid, b);
  if (!page) return;
  let found;
  for (const li of page.querySelectorAll('li')) {
    if (!found && li.getBoundingClientRect().top >= b) {
      page.classList.add('split');
      page.insertAdjacentHTML('afterend', '<section class="page virtual"><div class="group"><ul class="horizontal latest"></ul></div></section>');
      found = page.nextSibling.querySelector('ul');
    }
    if (found) found.appendChild(li);
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
  
  grid.style.width = '';
  if (beside.offsetWidth) {
    calculateNewWidth(grid, beside);
  }
  
  calculatePageSplit(grid, beside.getBoundingClientRect().bottom);
}

function alignLists() {
  all('ul.horizontal li.virtual', li => li.parentNode.removeChild(li));
  
  requestAnimationFrame(() => {
    all('ul.horizontal', ul => {
      let ulWidth = ul.clientWidth;
      if (!ul.firstElementChild) return;
      
      const style = window.getComputedStyle(ul.firstElementChild);
      
      let liWidth = ul.firstElementChild.getBoundingClientRect().width + parseFloat(style.marginLeft) + parseFloat(style.marginRight);
      
      let columnCount = Math.floor(ulWidth / liWidth);
      let itemsLastRow = ul.children.length % columnCount;
      
      console.log(columnCount);
      
      if (itemsLastRow == 0) return;
      
      while (itemsLastRow++ < columnCount) {
        ul.appendChild(ul.firstElementChild.cloneNode());
        ul.lastChild.classList.add('virtual');
      }
    });
  });
}

ready(() => {
  const columnRight = document.querySelector('.grid-root.column-right');
  if (!columnRight) {
    alignLists();
    return window.addEventListener('resize', alignLists);
  }
  
  const columnLeft = document.querySelector('.column-left');
  
  function resize() {
    alignLists();
    resizeGrid(columnLeft, columnRight);
  }
  
  window.addEventListener('resize', resize);
  resize();
});
