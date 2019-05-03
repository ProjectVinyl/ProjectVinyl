import { pushUrl } from './history';
import { bindEvent } from '../jslim/events';

export function encodeParamaters(data) {
  return Object.keys(data).map(key => `${encodeURIComponent(key)}=${encodeURIComponent(data[key])}`).join('&');
}

export function decodeParameters(data) {
  return data.toString().split('&').reduce((values, pair) => {
    const item = pair.trim().split('=');
    if (!item[0].length) return values;
    if (item.length < 2) item.push('');
    values[decodeURIComponent(item[0])] = decodeURIComponent(item[1]);
    return values;
  }, {});
}

export function QueryParameters(raw, historyObj) {
  this.historyObj = historyObj;
  this.values = typeof raw === 'string' ? decodeParameters(raw) : raw;
}

QueryParameters.prototype = {
  getItem(key) {
    return this.values[key];
  },
  setItem(key, value) {
    this.values[key] = value;
    if (this.historyObj && this.historyObj.pushState) {
      pushUrl(`${document.location.href.split('?')[0]}?${this.toString()}`);
    }
    return this;
  },
  clone() {
    return new QueryParameters(this);
  },
  toString() {
    return encodeParamaters(this.values);
  }
};

function statePopped() {
  QueryParameters.current = new QueryParameters(`${document.location.href}?`.split('?')[1], window.history);
}

bindEvent(window, 'popstate', statePopped);
statePopped();
