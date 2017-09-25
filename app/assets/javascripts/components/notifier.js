import { docTitle } from '../utils/doctitle';
import { ready } from '../jslim/events';

function updateCounter(counter, count) {
  counter.dataset.count = count;
  counter.innerText = count > 999 ? '999+' : count;
  // Kickstart the animation again
  counter.style.display = 'none';
  requestAnimationFrame(() => counter.style.display = '');
}

function getCount(element) {
  return parseInt(element.dataset.count) || 0;
}

function initWorker() {
  const worker = new SharedWorker(window.notifierUrl);
  let windowFocused = true;
  
  const title = docTitle();
  var messageHandlers = {
    feeds: document.querySelector('.notices-bell .feed-count'),
    notices: document.querySelector('.notices-bell .notification-count'),
    mail: document.querySelector('.notices-bell  .message-count')
  };
  
  worker.port.addEventListener('message', e => {
    notifyUser(e.data.command, e.data.count);
  });
  
  window.addEventListener('focus', () => {
    windowFocused = true;
  });
  window.addEventListener('blur', () => {
    windowFocused = false;
    title.removePrefix();
  });
  window.onbeforeunload = () => {
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
}

ready(() => {
  const giveMeNotifications = document.getElementById('give_me_notifications');
  if (giveMeNotifications) {
    giveMeNotifications.checked = window.SharedWorker && !!localStorage.give_me_notification;
    giveMeNotifications.addEventListener('change', e => {
      if (e.target.checked) {
        localStorage.give_me_notifications = e.target.checked;
      } else {
        localStorage.removeItem('give_me_notifications');
      }
    });
  }
  
  if (window.current_user && window.SharedWorker && !!localStorage.give_me_notifications) {
    initWorker();
  }
});
