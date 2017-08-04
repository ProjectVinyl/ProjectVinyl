import { tryUnmarshal } from './misc';

export const cookies = {
  get: function getCookie(key) {
    key = document.cookie.replace(new RegExp('(?:(?:^|.*;\s*)' + key + '\s*=\s*([^;]*).*$)|^.*$'), '$1');
    if (key) return tryUnmarshal(decodeURIComponent(key));
  },
  set: function setCookie(key, value) {
    if (value == null || value === undefined || isNaN(value)) value = '';
    document.cookie = key + '=' + encodeURIComponent(value) + ';';
  }
};
