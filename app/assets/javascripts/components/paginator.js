import { fetchJson } from '../utils/requests.js';
import { QueryParameters } from '../utils/queryparameters.js';

function repaintPages(context, page, pages) {
  const id = context.dataset.id;
  let index = page > 4 ? page - 4 : 0;

  [].forEach.call(context.querySelectorAll('.pages .button'), button => {
    if (index > page + 4 || index > pages) {
      button.parentNode.removeChild(button);
    } else {
      button.dataset.pageTo = index;
      button.href = '?' + QueryParameters.current.clone().setItem(id, index + 1).toString();
      button.innerText = index + 1;
      if (index == page) {
        button.classList.add('selected');
      }
    }
    index++;
  });

  context = context.querySelector('.pages');

  while (index <= page + 4 && index <= pages) {
    context.insertAdjacentHTML('beforeend', `<a class="button${index === page ? ' selected' : ''}" data-page-to="${index}" href="?${QueryParameters.current.clone(id, ++index).toString()}">${index}</a>`);
  }

  QueryParameters.current.setItem(id, page + 1);
}

function populatePage(context, json) {
  const container = context.querySelector('ul');

  container.innerHTML = json.content;
  container.classList.remove('waiting');
  context.dataset.page = json.page;

  [].forEach.call(context.querySelectorAll('.pagination'), page => {
    repaintPages(page, json.page, json.pages);
  });
}

function requestPage(context, page) {
  // Avoid no-op
  if (page == context.dataset.page) return;

  context.dataset.page = page;
  page = parseInt(page, 10);

  context.querySelector('ul').classList.add('waiting');
  context.querySelector('.pagination .pages .button.selected').classList.remove('selected');

  fetchJson('GET', `/ajax/${context.dataset.type}?page=${page}${context.dataset.args ? '&' + context.dataset.args : ''}`)
    .then(response => response.json())
    .then(json => {
      populatePage(context, json);
    });
}

const paginator = {
  repaint(context, json) {
    context.querySelector('.pagination .pages .button.selected').classList.remove('selected');
    populatePage(context, json);
  },

  go(button) {
    requestPage(button.closest('.paginator'), button.dataset.pageTo);
    if (!button.classList.contains('selected')) button.parentNode.classList.remove('hover');
  }
};

function setupPagination() {
  document.addEventListener('click', event => {
    // Left-click only, no modifiers
    if (event.button !== 0) return;
    if (event.ctrlKey || event.shiftKey) return;

    const target = event.target.closest('.pagination .pages .button, .pagination .button.left, .pagination .button.right');
    if (target) {
      paginator.go(target);
      event.preventDefault();
    }
  });
}

if (document.readyState !== 'loading') setupPagination();
else document.addEventListener('DOMContentLoaded', setupPagination);

export { paginator };
