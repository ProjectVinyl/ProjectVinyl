export function getAppKey(key) {
	const meta = document.querySelector('meta[name="' + key + '"]');
	return meta ? JSON.parse(meta.getAttribute('content')) : null;
}
