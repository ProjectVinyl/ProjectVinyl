/*
 * For tabs that keep a count of their content.
 */
import { bindEvent } from '../../jslim/events';

bindEvent(document, 'ajax:complete', e => {
  const tabs = e.detail.data.tabs;
  if (tabs) Object.keys(tabs).forEach(key => {
    const tab = document.querySelector(`.tab-set a.button[data-live-tab="${key}"] .count`);
    if (tab) tab.innerText = tabs[key] ? `(${tabs[key]})` : '';
  });
});
