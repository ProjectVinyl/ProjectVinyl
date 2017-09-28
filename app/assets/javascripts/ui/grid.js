import { ready } from '../jslim/events';
import { all } from '../jslim/dom';

const MARGIN = 60,
      COLUMN_WIDTH = 182,
      COLUMN_SPACING = 45,
      SIDEBAR_WIDTH = 255,
      SIDEBAR_SPACING = 15;

function calculateNewWidth(grid, beside) {
  const maxWidth = grid.parentNode.clientWidth - SIDEBAR_WIDTH;
  let calculatedWidth = maxWidth + 1;
  let n = 10;
  
  do {
    calculatedWidth = (MARGIN * 2) + (COLUMN_WIDTH * n) + (COLUMN_SPACING * --n);
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

ready(() => {
  const columnRight = document.querySelector('.grid-root.column-right');
  if (!columnRight) return;
  const columnLeft = document.querySelector('.column-left');
  
  function resize() {
    resizeGrid(columnLeft, columnRight);
  }
  
  window.addEventListener('resize', resize);
  resize();
});