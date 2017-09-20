import { pushUrl } from './history';

export function encodeParamaters(data) {
  return Object.keys(data).map(key => `${encodeURIComponent(key)}=${encodeURIComponent(data[key])}`).join('&');
}

export function decodeParameters(data) {
	return data.toString().split('&').reduce((values, pair) => {
		const item = pair.split('=');
		if (item.length < 2) item.push('');
		values[decodeURIComponent(item[0])] = decodeURIComponent(item[1]);
	}, {});
}

export function QueryParameters(raw, historyObj) {
	this.historyObj = historyObj;
  this.values = decodeParameters(raw);
}

QueryParameters.prototype = {
  getItem: function(key) {
    return this.values[key];
  },
  setItem: function(key, value) {
    this.values[key] = value;
    if (this.historyObj && this.historyObj.pushState) {
			pushUrl(`${document.location.href.split('?')[0]}?${this.toString()}`);
    }
    return this;
  },
  clone: function() {
    return new QueryParameters(this);
  },
  toString: function() {
    return encodeParamaters(this.values);
  }
};

function statePopped() {
  QueryParameters.current = new QueryParameters(`${document.location.href}?`.split('?')[1], window.history);
}

window.addEventListener('popstate', statePopped);
statePopped();
