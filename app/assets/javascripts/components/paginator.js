import { ajax } from '../utils/ajax';
import { QueryParameters } from '../utils/queryparameters';
import { bindEvent, addDelegatedEvent, dispatchEvent } from '../jslim/events';

function requestPage(context, page, force) {
  // Avoid no-op
  if (!force && page == context.dataset.page) return;
  
  context.dataset.page = page;
  page = parseInt(page, 10);
  
  context.classList.add('waiting');

  ajax.get(`${context.dataset.type}.json?order=${context.dataset.order}&page=${page}${context.dataset.args ? `&${context.dataset.args}` : ''}`).json(json => {
    repaintPagination(context, json);
  });
}

export function repaintPagination(context, json) {
  const container = context.querySelector('ul, .items');
  container.innerHTML = json.content;
  context.classList.remove('waiting');
  context.dataset.page = json.page;
  const paginatorHtml = json.paginate.replace(/%7Bpage%7D|{page}/g, context.dataset.id);
  context.querySelectorAll('.pagination').forEach(page => page.innerHTML = paginatorHtml);
  QueryParameters.current.setItem(context.dataset.id, json.page);
  dispatchEvent('pagechange', json, container);
}

addDelegatedEvent(document, 'click', '.pagination .button[data-page-to], .pagination .refresh', (event, target) => {
  // Left-click only, no modifiers
  if (event.button !== 0 || event.ctrlKey || event.shiftKey) return;

  const context = target.closest('.paginator');
  requestPage(context, target.dataset.pageTo || context.dataset.page, target.classList.contains('refresh'));
  event.preventDefault();
});

bindEvent(window, 'popstate', event => {
  document.querySelectorAll('.paginator').forEach(context => requestPage(context, QueryParameters.current.getItem(context.dataset.id)));
});
