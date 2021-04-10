import { all } from '../../../jslim/dom';

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

export function resizeGrid(grid, beside) {
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
