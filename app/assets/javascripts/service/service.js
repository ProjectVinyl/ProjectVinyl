import { ajax } from '../utils/ajax';

let workerStatus = 0;

const STOPPED = 0, CHANGING = 1, STARTED = 2;

function alterSubscription(callback) {
	navigator.serviceWorker.ready.then(worker => {
		worker.pushManager.getSubscription().then(sub => callback(worker, sub));
	});
}

function failsRequirements(state) {
	if (workerStatus != state) return true;
	workerStatus = CHANGING;
	
	if (!navigator.serviceWorker) {
		console.error('Service worker is not supported in this browser.');
		return true;
	}
	
	if (!("Notification" in window)) {
		console.error("This browser does not support desktop notifications.");
		return;
	}
	
	if (Notification.permission !== "default") return;
	Notification.requestPermission();
}

export function deregisterWorker(callback) {
	if (!failsRequirements(STARTED)) return;
	
	alterSubscription((worker, sub) => {
		if (sub) sub.unsubscribe().then(() => {
			let js = sub.toJSON();
			ajax.post('/services/deregister', {
				endpoint: js.endpoint,
				auth: js.keys.auth,
				p256dh: js.keys.p256dh
			}).text(() => {
				console.log('Service Stopped');
				workerStatus = STOPPED;
				callback();
			});
		});
	});
}

export function readyWorker(callback, readyCallback) {
	if (failsRequirements(STOPPED)) return;
	
	navigator.serviceWorker.register('/serviceworker.js', {scope: '/'});
	navigator.serviceWorker.addEventListener('message', callback);
	
	alterSubscription((worker, sub) => {
		if (!sub) worker.pushManager.subscribe({
			userVisibleOnly: true,
			applicationServerKey: vapid_public_key
		}).then(sub => {
			let js = sub.toJSON();
			ajax.post('/services/register', {
				endpoint: js.endpoint,
				auth: js.keys.auth,
				p256dh: js.keys.p256dh
			}).text(() => {
				console.log('Service Ready');
				workerStatus = STARTED;
				if (readyCallback) readyCallback();
			});
		});
	});
}
