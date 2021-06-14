import { deregisterWorker } from './service';
import { docTitle } from '../utils/doctitle';

function updateCounter(title, counter, count) {
	counter.dataset.count = count;
	counter.innerText = count > 999 ? '999+' : count;
	// Kickstart the animation again
	counter.style.display = 'none';
	requestAnimationFrame(() => counter.style.display = '');
  title.togglePrefix(count);
}

export function toggle(enable, readyCallback) {
  if (enable) {
    const title = docTitle();
    const counters = {
      feeds: '.notices-bell .feed-count',
      notices: '.notices-bell .notification-count',
      mail: '.notices-bell  .message-count'
    };

    registerWorker(e => {
      console.log('Got back' + e);
      const handler = counters[e.data.command];

      if (!handler) return;
      
      updateCounter(title, document.querySelector(handler), e.data.count);
    }, readyCallback);
  } else {
    deregisterWorker(readyCallback);
  }
}