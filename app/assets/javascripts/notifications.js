let feed_count = 0;
let notifications_count = 0;
let message_count = 0;

const step_delay_increment = 15000;
let step_delay = 30000;

let control_flag = null;
let ports = [];

function heartbeat() {
  const request = new XMLHttpRequest();
  request.onreadystatechange = function() {
    if (request.readyState == XMLHttpRequest.DONE) {
      if (request.status == 200) {
        const json = JSON.parse(request.responseText);
        sendMessage(json);
        if (step_delay > 30000) step_delay -= step_delay_increment;
      } else {
        step_delay += step_delay_increment;
      }
      if (ports.length > 0) {
        control_flag = setTimeout(heartbeat, step_delay);
      }
    }
  };
  let url = '/ajax/notifications?';
  if (notifications_count !== undefined) url += `notes=${notifications_count}`;
  if (feed_count !== undefined) url += `&feeds=${feed_count}`;
  if (message_count !== undefined) url += `&mail=${message_count}`;
  request.open('GET', url, true);
  request.send();
}

function sendMessage(msg) {
  ports = ports.filter(port => {
    try {
      if (msg.feeds !== undefined && msg.feeds != feed_count) {
        port.postMessage({ command: 'feeds', count: feed_count = msg.feeds });
      }
      if (msg.notices !== undefined && msg.notices != notifications_count) {
        port.postMessage({ command: 'notices', count: notifications_count = msg.notices });
      }
      if (msg.mail !== undefined && msg.mail != message_count) {
        port.postMessage({ command: 'mail', count: message_count = msg.mail });
      }
    } catch (ex) {
      return false;
    }
    return true;
  });
}

function recieveMessage(e) {
  if (e.data.command == 'connect') {
    feed_count = e.data.feeds;
    notifications_count = e.data.notices;
    ports.push(this);
    if (ports.length == 1) {
      control_flag = setTimeout(heartbeat, step_delay * 2);
    }
  } else if (e.data.command == 'disconnect' && ports.length > 0) {
    ports.splice(ports.indexOf(this), 1);
    if (this.chatId) this.chatId.remove();
    if (ports.length == 0 && control_flag) {
      clearTimeout(control_flag);
      self.close();
    }
  }
}

self.addEventListener('connect', e => {
  const port = e.ports[0];
  port.addEventListener('message', recieveMessage);
  port.start();
});
