import { addDelegatedEvent } from '../../jslim/events';

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

  if (tabset.classList.contains('selected')) {
    const otherTabs = tabset.parentNode.querySelectorAll('li.button:not([data-disabled])[data-target]');

    if (otherTabs.length) {
      const index = [].indexOf.call(otherTabs, tabset);

      if (index < otherTabs.length - 1) {
        focusTab(otherTabs[index + 1]);
      } else if (index > 0) {
        focusTab(otherTabs[index - 1]);
      }
    }
  }

  toRemove.parentNode.removeChild(toRemove);

  tabset.classList.add('hidden');

  setTimeout(() => tabset.parentNode.removeChild(tabset), 25);
});
