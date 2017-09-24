const counters = { feeds: 0, notices: 0, mail: 0 };
const keys = Object.keys(counters);

const stepDelayIncrement = 15000;

let stepDelay = 30000;
let controlFlag = null;
let ports = [];

const recievers = {
  connect: (port, msg) => {
    keys.forEach(key => counters[key] = msg[key]);
    ports.push(port);
    if (ports.length == 1) controlFlag = setTimeout(heartbeat, stepDelay * 2);
  },
  disconnect: (port, msg) => {
    if (!ports.length) return;
    ports.splice(ports.indexOf(port), 1);
    if (!ports.length && controlFlag) {
      clearTimeout(controlFlag);
      this.close();
    }
  }
};

function heartbeat() {
  const request = new XMLHttpRequest();
  request.onreadystatechange = () => {
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
  let url = [];
  keys.forEach(key => {
    if (counters[key] !== undefined) url.push(`${key}=${counters[key]}`);
  });
  request.open('GET', `/ajax/notifications?${url.join('&')}`, true);
  request.send();
}

function sendMessage(msg) {
  ports = ports.filter(port => {
    try {
      keys.forEach(counter => {
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

this.addEventListener('connect', e => {
  const port = e.ports[0];
  port.addEventListener('message', e => {
    if (receivers[e.data.command]) receivers[e.data.command](port, e.data);
  });
  port.start();
});
