import { getAppKey } from '../data/all';
import { ajax } from '../utils/ajax';

let workerStatus = 0;

// Application push notifications authenticated via VAPID
const vapid_public_key = new Uint8Array(getAppKey('vapid_public_key'));

const STOPPED = 0, CHANGING = 1, STARTED = 2;

function alterSubscription(callback) {
	navigator.serviceWorker.ready.then(worker => {
		worker.pushManager.getSubscription().then(sub => callback(worker, sub));
	});
}

function transitionState(initialState, callback) {
  if (workerStatus != initialState) return;

	workerStatus = CHANGING;
	
  if (document.location.protocol !== 'https:') {
    console.warn('Service worker requires a secured context.');
    return;
  }
  
	if (!navigator.serviceWorker) {
		console.warn('Service worker is not supported in this browser.');
		return;
	}
	
	if (!("Notification" in window)) {
		console.warn("This browser does not support desktop notifications.");
		return;
	}
	
	if (Notification.permission === "default") {
    Notification.requestPermission();
  }

  callback();
}

function subParams(sub) {
  let js = sub.toJSON();
  return {
    endpoint: js.endpoint,
    auth: js.keys.auth,
    p256dh: js.keys.p256dh
  };
}

export function deregisterWorker(callback) {
	transitionState(STARTED, () => {
    alterSubscription((worker, sub) => {
      if (!sub) return;

      sub.unsubscribe().then(() => ajax.post('/services/deregister', subParams(sub)).text(() => {
        console.log('Service Stopped');
        workerStatus = STOPPED;
        callback();
      }));
    });
  });
}

export function readyWorker(callback, readyCallback) {
	transitionState(STOPPED, () => {
    navigator.serviceWorker.register('/serviceworker.js', {scope: '/'});
    navigator.serviceWorker.addEventListener('message', callback);

    alterSubscription((worker, sub) => {
      if (sub) return;

      worker.pushManager.subscribe({
        userVisibleOnly: true, applicationServerKey: vapid_public_key
      }).then(sub => ajax.post('/services/register', subParams(sub)).text(() => {
        console.log('Service Ready');
        workerStatus = STARTED;

        if (readyCallback) {
          readyCallback();
        }
      }));
    });
	});
}
