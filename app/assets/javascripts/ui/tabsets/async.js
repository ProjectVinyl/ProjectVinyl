import { ajaxGet } from '../../utils/ajax';
import { addDelegatedEvent } from '../../jslim/events';
import { pushUrl } from '../../utils/history';

addDelegatedEvent(document, 'click', '.tab-set.async a.button:not([data-disabled])', function(e) {
  if (e.button !== 0) return;
  if (this.classList.contains('selected')) return;
  e.preventDefault();

  const parent = this.parentNode;
  const other = parent.querySelector('.selected');
  const holder = document.querySelector(`.tab[data-tab="${parent.dataset.target}"]`);
  const url = this.getAttribute('href');

  other.classList.remove('selected');
  this.classList.add('selected');
  holder.classList.add('waiting');

  pushUrl(url);
  ajaxGet(`${url}/tabs.json`, { page: this.dataset.page || 0 }).json(json => {
    holder.innerHTML = json.content;
    holder.classList.remove('waiting');
  });
});
