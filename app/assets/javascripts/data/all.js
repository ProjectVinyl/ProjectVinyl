import { tryUnmarshal } from '../utils/misc';

export function getAppKey(key) {
	const meta = document.querySelector('meta[name="' + key + '"]');
	return meta ? tryUnmarshal(meta.getAttribute('content'), meta.getAttribute('content')) : null;
}
