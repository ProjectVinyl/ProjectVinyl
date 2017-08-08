import { tryUnmarshal } from './misc';

function extractCookieValue(key) {
  let cook = document.cookie;
  var index = cook.lastIndexOf(key);
  if (index < 0) return null;
  cook = cook.substring(index, cook.length).split(';')[0];
  index = cook.indexOf('=');
  if (index < 0) return null;
  return cook.substring(index + 1, cook.length).trim();
}

export const cookies = {
  get: function getCookie(key) {
    key = extractCookieValue(key);
    if (key) return tryUnmarshal(decodeURIComponent(key));
  },
  set: function setCookie(key, value) {
    if (value == null || value === undefined || isNaN(value)) value = '';
    document.cookie = key + '=' + encodeURIComponent(value) + ';';
  }
};
