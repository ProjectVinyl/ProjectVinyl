import { readyWorker } from './service';
import { docTitle } from '../utils/doctitle';

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
}

export function initWorker(callback) {
	const title = docTitle();
	
	readyWorker(e => {
		console.log('Got back' + e);
		const handler = counters[e.data.command];
	    if (!handler) return;
	    
	    updateCounter(document.querySelector(handler), e.data.count);
	    title.togglePrefix(e.data.count);
	}, callback);
}
