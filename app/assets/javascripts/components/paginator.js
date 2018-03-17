import { ajax } from '../utils/ajax';
import { QueryParameters } from '../utils/queryparameters';
import { ready } from '../jslim/events';
import { all } from '../jslim/dom';

function populatePage(context, json) {
  const container = context.querySelector('ul, .items');
  container.innerHTML = json.content;
  context.classList.remove('waiting');
  context.dataset.page = json.page;
  all(context, '.pagination', page => {
    page.innerHTML = json.paginate.replace(/%7Bpage%7D|{page}/g, context.dataset.id);
  });
}

function requestPage(context, page, force) {
  // Avoid no-op
  if (!force && page == context.dataset.page) return;
  
  context.dataset.page = page;
  page = parseInt(page, 10);
  
  context.classList.add('waiting');
  
  context.querySelector('.pagination .pages .button.selected').classList.remove('selected');
  
  ajax.get(`${context.dataset.type}.json?page=${page}${context.dataset.args ? `&${context.dataset.args}` : ''}`).json(json => {
    populatePage(context, json);
    QueryParameters.current.setItem(context.dataset.id, json.page + 1);
  });
}

export function repaintPagination(context, json) {
  context.querySelector('.pagination .pages .button.selected').classList.remove('selected');
  populatePage(context, json);
  QueryParameters.current.setItem(context.dataset.id, json.page + 1);
}

ready(() => {
  document.addEventListener('click', event => {
    // Left-click only, no modifiers
    if (event.button !== 0 || event.ctrlKey || event.shiftKey) return;
    const target = event.target.closest('.pagination .button[data-page-to], .pagination .refresh');
    if (target) {
      const context = target.closest('.paginator');
      requestPage(context, target.dataset.pageTo || context.dataset.page, target.classList.contains('refresh'));
      event.preventDefault();
    }
  });
  window.addEventListener('popstate', event => {
    all('.paginator', context => {
      requestPage(context, QueryParameters.current.getItem(context.dataset.id));
    });
  });
});
