const getAppKey = function(key) {
	const meta = document.querySelector('meta[name="' + key + '"]');
	return meta ? JSON.parse(meta.getAttribute('content')) : null;
};

// The current signed-in user.
const current_user = getAppKey('current_user');
