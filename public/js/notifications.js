var feed_count = 0;
var notifications_count = 0;

var step_delay_increment = 15000;
var step_delay = 30000;

var control_flag = null;
var ports = [];

function heartbeat() {
  var request = new XMLHttpRequest();
  request.onreadystatechange = function() {
    if (request.readyState == XMLHttpRequest.DONE) {
      if (request.status == 200) {
        var json = JSON.parse(request.responseText);
        sendMessage(json);
        if (step_delay > 30000) step_delay -= step_delay_increment;
      } else {
        step_delay += step_delay_increment;
      }
      if (ports.length > 0 > 0) {
        control_flag = setTimeout(heartbeat, step_delay);
      }
    }
  };
  request.open('GET', '/ajax/notifications?notes=' + notifications_count + '&feeds=' + feed_count, true);
  request.send();
}

function sendMessage(msg) {
  ports.filter(function(port) {
    if (msg.feeds != feed_count) {
      port.postMessage({ command: 'feeds', count: (feed_count = msg.feeds) });
    }
    if (msg.notices != notifications_count) {
      port.postMessage({ command: 'notices', count: (notifications_count = msg.notices) });
    }
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
  } else if (e.data.command == 'disconnect' && connections > 0) {
    ports.splice(ports.indexOf(this), 1)
    if (ports.length == 0 && control_flag) {
      clearTimeout(control_flag);
      self.close();
    }
  }
}

self.addEventListener('connect', function(e) {
  var port = e.ports[0];
  port.addEventListener('message', recieveMessage);
  port.start();
});