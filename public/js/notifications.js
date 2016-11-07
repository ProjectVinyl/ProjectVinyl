var feed_count = 0;
var notifications_count = 0;

var step_delay_increment = 15000;
var step_delay = 30000;
var chat_delay = 300;

var control_flag = null;
var ports = [];
var chatCache = {};
var active_chats = [];

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
      if (ports.length > 0) {
        control_flag = setTimeout(heartbeat, active_chats.length > 0 ? chat_delay : step_delay);
      }
    }
  };
  var url = '/ajax/notifications?';
  if (notifications_count !== undefined) url += 'notes=' + notifications_count;
  if (feed_count !== undefined) url += '&feeds=' + feed_count;
  if (active_chats.length > 0) url += '&chat=' + active_chats.join(',');
  request.open('GET', url, true);
  request.send();
}

function sendMessage(msg) {
  ports = ports.filter(function(port) {
    try {
      if (msg.feeds !== undefined && msg.feeds != feed_count) {
        port.postMessage({ command: 'feeds', count: (feed_count = msg.feeds) });
      }
      if (msg.notices !== undefined && msg.notices != notifications_count) {
        port.postMessage({ command: 'notices', count: (notifications_count = msg.notices) });
      }
      if (port.chatId && msg.chats) {
        msg.chats.filter(function(chat) {
          if (chat.id == port.chatId.id) {
            port.chatId.last = chat.last;
            port.postMessage({ command: 'chat', content: chat.content});
          }
        });
      }
    } catch (ex) {
      if (port.chatId) port.chatId.remove();
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
  } else if (e.data.command == 'chatstate') {
    if (e.data.opened) {
      if (active_chats.length == 0 && control_flag) {
        clearTimeout(control_flag);
        control_flag = setTimeout(heartbeat, chat_delay);
      }
      if (!this.chatId) {
        ChatRecord.new(this, e.data.id, e.data.last);
      } else {
        this.chatId.add();
      }
    } else {
      if (this.chatId) this.chatId.detach();
    }
  }
}

function ChatRecord(sender, id, last) {
  this.id = id;
  this.last = last;
  this.add();
}
ChatRecord.new = function(sender, id, last) {
  if (chatCache[id]) return chatCache[id].last = last;
  sender.chatId = chatCache[id] = new ChatRecord(sender, id, last);
}
ChatRecord.prototype = {
  toString: function() {
    return this.id + ':' + this.last;
  },
  remove: function() {
    chatCache[this.id] = undefined;
    this.detach();
  },
  detach: function() {
    active_chats.splice(active_chats.indexOf(this), 1);
  },
  add: function() {
    active_chats.push(this);
  }
}

self.addEventListener('connect', function(e) {
  var port = e.ports[0];
  port.addEventListener('message', recieveMessage);
  port.start();
});