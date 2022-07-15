import { tryUnmarshal } from './misc';

export const DAYS = 24 * 60 * 60 * 1000;
export const COOKIE_MAX_AGE = 30 * DAYS;

function extractCookieValue(key) {
  let cook = document.cookie;
  let index = cook.lastIndexOf(key);
  if (index < 0) return null;
  cook = cook.substring(index, cook.length).split(';')[0];
  index = cook.indexOf('=');
  if (index < 0) return null;
  return cook.substring(index + 1, cook.length).trim();
}

export const cookies = {
  get: (key, def) => {
    key = extractCookieValue(key);
    if (key) return tryUnmarshal(decodeURIComponent(key), def);
    return def;
  },
  set: (key, value, params) => {
    params = params || {};
    let age = params.age || COOKIE_MAX_AGE;
    const path = params.path || '/';

    if (value === '' || value === null || value === undefined || isNaN(value)) {
      value = '';
      age = -1;
    }
    if (params.session) {
      age = 'Session';
    }

    document.cookie = `${key}=${value}; max-age=${age}; path=${path};`;
  }
};
