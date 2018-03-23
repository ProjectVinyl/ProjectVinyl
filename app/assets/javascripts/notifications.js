var counters = { feeds: 0, notices: 0, mail: 0 };
var keys = Object.keys(counters);

var stepDelayIncrement = 15000;

var stepDelay = 30000;
var controlFlag = null;
var ports = [];

var self = this;

var receivers = {
  connect: function(port, msg) {
    keys.forEach(function(key) {
      counters[key] = msg[key];
    });
    ports.push(port);
    if (ports.length == 1) controlFlag = setTimeout(heartbeat, stepDelay * 2);
  },
  disconnect: function(port, msg) {
    if (!ports.length) return;
    ports.splice(ports.indexOf(port), 1);
    if (!ports.length && controlFlag) {
      clearTimeout(controlFlag);
      self.close();
    }
  }
};

function heartbeat() {
  const request = new XMLHttpRequest();
  request.onreadystatechange = function() {
    if (request.readyState == XMLHttpRequest.DONE) {
      if (request.status == 200) {
        sendMessage(JSON.parse(request.responseText));
        if (stepDelay > 30000) stepDelay -= stepDelayIncrement;
      } else {
        stepDelay += stepDelayIncrement;
      }
      if (ports.length) {
        controlFlag = setTimeout(heartbeat, stepDelay);
      }
    }
  };
  var url = [];
  keys.forEach(function(key) {
    if (counters[key] !== undefined) url.push(key + '=' + counters[key]);
  });
  request.open('GET', '/ajax/notifications?' + url.join('&'), true);
  request.send();
}

function sendMessage(msg) {
  ports = ports.filter(function(port) {
    try {
      keys.forEach(function(counter) {
        if (msg[counter] !== undefined && msg[counter] != counters[counter]) {
          port.postMessage({ command: counter, count: msg[counter] });
          counters[counter] = msg[counter];
        }
      });
    } catch (ex) {
      return false;
    }
    return true;
  });
}

this.addEventListener('connect', function(e) {
  var port = e.ports[0];
  port.addEventListener('message', function(e) {
    if (receivers[e.data.command]) receivers[e.data.command](port, e.data);
  });
  port.start();
});
