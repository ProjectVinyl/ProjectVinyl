import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';
import { pushUrl } from '../utils/history';

function focusTab(me) {
  if (!me || me.classList.contains('selected') || !me.dataset.target) {
    return;
  }
  // Unfocus other tab first
  const other = me.parentNode.querySelector('.selected');
  if (other) {
    other.classList.remove('selected');
    const otherTab = document.querySelector('div[data-tab="' + other.dataset.target + '"]');
    otherTab.classList.remove('selected');
    otherTab.dispatchEvent(new CustomEvent('tabblur', { bubbles: true }));
  }

  me.classList.add('selected');
  const thisTab = document.querySelector('div[data-tab="' + me.dataset.target + '"]');
  thisTab.classList.add('selected');
  thisTab.dispatchEvent(new CustomEvent('tabfocus', { bubbles: true }));
}

jSlim.on(document, 'click', '.tab-set > li.button:not([data-disabled])', function() {
  focusTab(this);
});

jSlim.on(document, 'click', '.tab-set > li.button i.fa-close',  function(e) {
  const tabset = this.parentNode;
  const toRemove = document.querySelector('div[data-tab="' + tabset.dataset.target + '"]');

  toRemove.parentNode.removeChild(toRemove);
  tabset.classList.add('hidden');

  setTimeout(() => tabset.parentNode.removeChild(tabset), 25);

  focusTab(tabset.parentNode.querySelector('li.button:not([data-disabled]):not(.hidden)[data-target]'));

  e.preventDefault();
  e.stopPropagation();
});

jSlim.on(document, 'click', '.tab-set.async a.button:not([data-disabled])', function(e) {
  e.preventDefault();
  if (this.classList.contains('selected')) return;

  const parent = this.parentNode;
  const other = parent.querySelector('.selected');
  const holder = document.querySelector('.tab[data-tab="' + parent.dataset.target + '"]');

  other.classList.remove('selected');
  this.classList.add('selected');
  holder.classList.add('waiting');
  
  pushUrl(this.getAttribute('href'));
  ajax.get(this.getAttribute('href') + '/tab', {
    page: this.dataset.page || 0
  }).json(function(json) {
    holder.innerHTML = json.content;
    holder.classList.remove('waiting');
  });
});

export { focusTab };
