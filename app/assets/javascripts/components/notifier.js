import { docTitle } from '../utils/doctitle.js';
import { jSlim } from '../utils/jslim.js';

function updateCounter(counter, count) {
  counter.dataset.count = count;
  counter.innerText = count > 999 ? '999+' : count;
  // Kickstart the animation again
  counter.style.display = 'none';
  setTimeout(function() {
    counter.style.display = '';
  }, 1);
}

function getCount(element) {
  return parseInt(element.dataset.count) || 0;
}

function initWorker() {
  var worker = new SharedWorker(window.notifierUrl);
  var windowFocused = true;
  
  var title = docTitle();
  var messageHandlers = {
    feeds: document.querySelector('.notices-bell .feed-count'),
    notices: document.querySelector('.notices-bell .notification-count'),
    mail: document.querySelector('.notices-bell  .message-count')
  };
  
  worker.port.addEventListener('message', function(e) {
    notifyUser(e.data.command, e.data.count);
  });
  
  window.addEventListener('focus', function() {
    windowFocused = true;
  });
  window.addEventListener('blur', function() {
    windowFocused = false;
    title.removePrefix();
  });
  window.onbeforeunload = function() {
    worker.port.postMessage({
      command: 'disconnect'
    });
    return null;
  };
  
  worker.port.start();
  worker.port.postMessage({
    command: 'connect',
    feeds: getCount(messageHandlers.feeds),
    notices: getCount(messageHandlers.notices),
    mail: getCount(messageHandlers.mail)
  });
  
  function notifyUser(type, count) {
    count = Number(count);
    if (count < 0 || !count) count = 0;
    var handler = messageHandlers[type];
    if (!handler) return;
    updateCounter(handler, count);
    title.togglePrefix(!windowFocused && count);
  }
  // Testing purposes
  // > notifyUser('feeds', 1);
  window.notifyUser = notifyUser;
}

jSlim.ready(function() {
  var giveMeNotifications = document.getElementById('give_me_notifications');
  if (giveMeNotifications) {
    giveMeNotifications.checked = window.SharedWorker && !!localStorage.give_me_notification;
    giveMeNotifications.addEventListener('change', function() {
      if (this.checked) {
        localStorage.give_me_notifications = this.checked;
      } else {
        localStorage.removeItem('give_me_notifications');
      }
    });
  }
  
  if (window.current_user && window.SharedWorker && !!localStorage.give_me_notifications) {
    initWorker();
  }
});
