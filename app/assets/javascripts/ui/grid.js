import { jSlim } from '../utils/jslim.js';

// For utils
function toEl(str) {
  const div = document.createElement('div');
  div.innerHTML = str;
  return div.children[0];
}

function height(el) {
  const style = getComputedStyle(el);
  return el.clientHeight - parseFloat(style.paddingTop) - parseFloat(style.paddingBottom);
}

function width(el) {
  const style = getComputedStyle(el);
  return el.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight);
}

function calculateNewWidth(grid, beside) {
  // subtract any padding
  var width = grid.parentNode.clientWidth - 195;
  var calculatedWidth = width + 1;
  var n = 10;

  // 60 is the margins of the .page, 182 is the column width, and 45 is the column spacing
  do {
    calculatedWidth = 60 + (182 * n) + 45 * --n + 60;
  } while (calculatedWidth > width);

  grid.style.width = `${calculatedWidth}px`;

  if (beside) {
    beside.style.width = `${beside.parentNode.clientWidth - (calculatedWidth + 15)}px`;
  }
}

// FIXME
function calculatePageSplit(grid, beside) {
  const b = jSlim.offset(beside).top + height(beside) + 10;

  for (const page of grid.querySelectorAll('.page')) {
    const t = jSlim.offset(page).top;
    if (t < b && (t + page.offsetHeight) > b) {
      for (const li of page.querySelectorAll('li')) {
        if (jSlim.offset(li).top > b) {
          li.classList.add('t');
          page.classList.add('split');

          const nx = toEl('<section class="page virtual"><div class="group"><ul class="horizontal latest" /></div></section>');
          const ul = nx.querySelector('ul');

          jSlim.all('.t, .t ~ li', t => ul.appendChild(t));
          page.insertAdjacentElement('afterend', nx);
          li.classList.remove('t');
          return;
        }
      }
      return;
    }
  }
}

function resizeGrid(grid, beside) {
  jSlim.all(grid, '.page.virtual', page => {
    const prev = page.previousSibling;
    prev.classList.remove('split');
    prev.querySelector('ul').appendChild(page.querySelector('li'));
    page.parentNode.removeChild(page);
  });

  grid.style.width = '';

  if (width(beside) > 0) {
    calculateNewWidth(grid, beside);
  }

  calculatePageSplit(grid, beside);
}

jSlim.ready(() => {
  if (document.querySelector('.grid-root')) {
    const columnLeft = document.querySelector('.column-left');
    const columnRight = document.querySelector('.column-right');

    function resize() {
      resizeGrid(columnLeft, columnRight);
    }

    window.addEventListener('resize', resize);
    resize();
  }
});
