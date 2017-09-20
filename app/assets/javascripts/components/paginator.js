import { ajax } from '../utils/ajax';
import { QueryParameters } from '../utils/queryparameters';
import { jSlim } from '../utils/jslim';

function populatePage(context, json) {
  const container = context.querySelector('ul');
  
  container.innerHTML = json.content;
  container.classList.remove('waiting');
  context.dataset.page = json.page;
  jSlim.all(context, '.pagination', page => {
    page.innerHTML = json.paginate.replace(/%7Bpage%7D|{page}/g, context.dataset.id);
  });
}

function requestPage(context, page) {
  // Avoid no-op
  if (page == context.dataset.page) return;
  
  context.dataset.page = page;
  page = parseInt(page, 10);
  
  context.querySelector('ul').classList.add('waiting');
  context.querySelector('.pagination .pages .button.selected').classList.remove('selected');
  
  ajax.get(`${context.dataset.type}?page=${page}${context.dataset.args ? `&${context.dataset.args}` : ''}`).json(json => {
    populatePage(context, json);
    QueryParameters.current.setItem(context.dataset.id, json.page + 1);
  });
}

const paginator = {
  repaint: function(context, json) {
    context.querySelector('.pagination .pages .button.selected').classList.remove('selected');
    populatePage(context, json);
    QueryParameters.current.setItem(context.dataset.id, json.page + 1);
  },
  go: function(button) {
    requestPage(button.closest('.paginator'), button.dataset.pageTo);
    if (!button.classList.contains('selected')) button.parentNode.classList.remove('hover');
  }
};

jSlim.ready(function() {
  document.addEventListener('click', event => {
    // Left-click only, no modifiers
    if (event.button !== 0 || event.ctrlKey || event.shiftKey) return;
    const target = event.target.closest('.pagination .button');
    if (target) {
      paginator.go(target);
      event.preventDefault();
    }
  });
  window.addEventListener('popstate', event => {
    jSlim.all('.paginator', context => {
      requestPage(context, QueryParameters.current.getItem(context.dataset.id));
    });
  });
});

export { paginator };
