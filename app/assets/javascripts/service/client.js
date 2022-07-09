import { deregisterWorker, registerWorker } from './service';
import { togglePrefix } from '../utils/doctitle';
import { formatNumber, formatWithDelimiters } from '../utils/numbers';

const counters = {
  feeds: '.notices-bell.feed-count',
  notices: '.notices-bell.notification-count',
  mail: '.notices-bell.message-count'
};

function updateCounter(counter, count) {
  if (count == counter.dataset.value) return;

  counter.dataset.value = count;
	counter.dataset.count = formatNumber(count, 9999);
  counter.title = count == 0 ? counter.dataset.label : `${counter.dataset.label} - ${formatWithDelimiters(count)}`;
  togglePrefix(count);

  requestAnimationFrame(() => {
    counter.classList.toggle('rebuff');
    requestAnimationFrame(() => counter.classList.toggle('rebuff'));
  });
}

export function toggle(enable, readyCallback) {
  if (enable) {
    registerWorker(e => {
      const handler = counters[e.data.command];

      if (!handler) return;
      
      document.querySelectorAll(handler).forEach(counter => updateCounter(counter, e.data.count));
    }, readyCallback);
  } else {
    deregisterWorker(readyCallback);
  }
}
