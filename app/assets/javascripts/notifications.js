var feedCount = 0;
var notificationsCount = 0;
var messageCount = 0;

var stepDelayIncrement = 15000;
var stepDelay = 30000;

var controlFlag = null;
var ports = [];

function heartbeat() {
  var request = new XMLHttpRequest();
  request.onreadystatechange = function() {
    if (request.readyState == XMLHttpRequest.DONE) {
      if (request.status == 200) {
        var json = JSON.parse(request.responseText);
        sendMessage(json);
        if (stepDelay > 30000) stepDelay -= stepDelayIncrement;
      } else {
        stepDelay += stepDelayIncrement;
      }
      if (ports.length > 0) {
        controlFlag = setTimeout(heartbeat, stepDelay);
      }
    }
  };
  var url = '/ajax/notifications?';
  if (notificationsCount !== undefined) url += 'notes=' + notificationsCount;
  if (feedCount !== undefined) url += '&feeds=' + feedCount;
  if (messageCount !== undefined) url += '&mail=' + messageCount;
  request.open('GET', url, true);
  request.send();
}

function sendMessage(msg) {
  ports = ports.filter(function(port) {
    try {
      if (msg.feeds !== undefined && msg.feeds != feedCount) {
        port.postMessage({ command: 'feeds', count: feedCount = msg.feeds });
      }
      if (msg.notices !== undefined && msg.notices != notificationsCount) {
        port.postMessage({ command: 'notices', count: notificationsCount = msg.notices });
      }
      if (msg.mail !== undefined && msg.mail != messageCount) {
        port.postMessage({ command: 'mail', count: messageCount = msg.mail });
      }
    } catch (ex) {
      return false;
    }
    return true;
  });
}

function recieveMessage(e) {
  if (e.data.command == 'connect') {
    feedCount = e.data.feeds;
    notificationsCount = e.data.notices;
    ports.push(this);
    if (ports.length == 1) {
      controlFlag = setTimeout(heartbeat, stepDelay * 2);
    }
  } else if (e.data.command == 'disconnect' && ports.length > 0) {
    ports.splice(ports.indexOf(this), 1);
    if (this.chatId) this.chatId.remove();
    if (ports.length == 0 && controlFlag) {
      clearTimeout(controlFlag);
      self.close();
    }
  }
}

self.addEventListener('connect', function(e) {
  var port = e.ports[0];
  port.addEventListener('message', recieveMessage);
  port.start();
});