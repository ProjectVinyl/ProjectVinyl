const counters = { feeds: 0, notices: 0, mail: 0 };
const keys = Object.keys(counters);

function sendMessage(msg) {
  self.clients.matchAll().then(clients => {
    clients.forEach(client => {
      client.postMessage(msg);
    });
  });
}

function sendCounterUpdate(msg) {
  keys.forEach(counter => {
    if (msg[counter] === undefined) return;
    const value = Math.max(0, Number(msg[counter]) || 0);
    if (value == counters[counter]) return;
    counters[counter] = value;

    sendMessage({
      command: counter,
      count: value
    });
  });
}

self.addEventListener('push', e => {
  const data = e.data.json();

  if (data.counters) {
    sendCounterUpdate(data.counters);
  }
  if (data.push) {
    e.waitUntil(self.registration.showNotification(data.push.title, data.push.params));
  }
});
