import { ajax } from '../utils/ajax';
import { addDelegatedEvent, bindEvent } from '../jslim/events';
import { pushUrl } from '../utils/history';

export function focusTab(me) {
  if (!me || me.classList.contains('selected') || !me.dataset.target) return;
  // Unfocus other tab first
  const other = me.parentNode.querySelector('.selected');
  if (other) {
    other.classList.remove('selected');
    const otherTab = document.querySelector(`div[data-tab="${other.dataset.target}"]`);
    otherTab.classList.remove('selected');
    otherTab.dispatchEvent(new CustomEvent('tabblur', { bubbles: true }));
  }
  
  me.classList.add('selected');
  const thisTab = document.querySelector(`div[data-tab="${me.dataset.target}"]`);
  thisTab.classList.add('selected');
  thisTab.dispatchEvent(new CustomEvent('tabfocus', { bubbles: true }));
}

addDelegatedEvent(document, 'click', '.tab-set > li.button:not([data-disabled])', (e, target) => {
  if (e.button !== 0) return;
  if (!e.target.closest('.fa-close')) focusTab(target);
});
addDelegatedEvent(document, 'click', '.tab-set > li.button i.fa-close',  (e, target) => {
  if (e.button !== 0) return;
  e.preventDefault();
  
  const tabset = target.parentNode;
  const toRemove = document.querySelector(`div[data-tab="${tabset.dataset.target}"]`);
  
  toRemove.parentNode.removeChild(toRemove);
  tabset.classList.add('hidden');
  
  setTimeout(() => tabset.parentNode.removeChild(tabset), 25);
  
  focusTab(tabset.parentNode.querySelector('li.button:not([data-disabled]):not(.hidden)[data-target]'));
});
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
  ajax.get(`${url}/tabs.json`, { page: this.dataset.page || 0 }).json(json => {
    holder.innerHTML = json.content;
    holder.classList.remove('waiting');
  });
});

bindEvent(document, 'ajax:complete', ev => {
  const tabs = ev.detail.data.tabs;
  if (tabs) Object.keys(tabs).forEach(key => {
    const tab = document.querySelector(`.tab-set a.button[data-live-tab="${key}"] .count`);
    if (tab) tab.innerText = tabs[key] ? `(${tabs[key]})` : '';
  });
});
