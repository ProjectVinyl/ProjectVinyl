import { deregisterWorker, registerWorker } from './service';
import { togglePrefix } from '../utils/doctitle';

const counters = {
  feeds: '.notices-bell .feed-count',
  notices: '.notices-bell .notification-count',
  mail: '.notices-bell  .message-count'
};

function updateCounter(counter, count) {
	counter.dataset.count = count;
	counter.innerText = count > 999 ? '999+' : count;
	// Kickstart the animation again
	counter.style.display = 'none';
	requestAnimationFrame(() => counter.style.display = '');
  togglePrefix(count);
}

export function toggle(enable, readyCallback) {
  if (enable) {
    registerWorker(e => {
      const handler = counters[e.data.command];

      if (!handler) return;
      
      updateCounter(document.querySelector(handler), e.data.count);
    }, readyCallback);
  } else {
    deregisterWorker(readyCallback);
  }
}