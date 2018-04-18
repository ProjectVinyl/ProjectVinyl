const counters = { feeds: 0, notices: 0, mail: 0 };
const keys = Object.keys(counters);

export function sendMessage(msg) {
  keys.forEach(counter => {
    if (msg[counter] === undefined) return;
    const value = Math.max(0, Number(msg[counter]) || 0);
    if (value == counters[counter]) return;
    counters[counter] = value;
    
    self.clients.matchAll().then(clients => {
    	clients.forEach(client => {
	    	client.postMessage({
	    		command: counter,
	    		count: value
	    	});
	    });
    });
  });
}

self.addEventListener('push', e => {
  const data = e.data.json();
  
  sendMessage(data.counters);
  
  e.waitUntil(self.registration.showNotification(data.push.title, data.push.params));
});
