import { tryUnmarshal } from './misc';

const DAYS = 24 * 60 * 60 * 1000;
const COOKIE_MAX_AGE = 30 * DAYS;

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
  get: key => {
    key = extractCookieValue(key);
    if (key) return tryUnmarshal(decodeURIComponent(key));
  },
  set: (key, value) => {
    if (value == null || value === undefined || isNaN(value)) {
      return document.cookie = `${key}=; max-age=-1; path=/;`;
    }
    document.cookie = `${key}=${encodeURIComponent(value)}; max-age=${COOKIE_MAX_AGE}; path=/;`;
  }
};
