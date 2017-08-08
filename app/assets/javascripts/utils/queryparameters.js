import { pushUrl } from './history';

function encodeParamaters(queryPars) {
  return queryPars.keys.map(function(k) {
    return k + '=' + encodeURIComponent(queryPars.values[k]);
  }).join('&');
}

function updateHistoryObj(queryPars) {
  if (queryPars.historyObj.pushState) {
    pushUrl(document.location.href.split('?')[0] + '?' + queryPars.toString());
  }
}

function QueryPars(raw, historyObj) {
  this.keys = [];
  this.values = {};
  this.historyObj = historyObj;
  if (raw.indexOf('&') > -1) {
    raw.split('&').forEach(function(pair) {
      var item = pair.split('=');
      if (item.length < 2) item.push('');
      if (this.keys.indexOf(item[0]) < 0) {
        this.keys.push(item[0]);
      }
      this.values[item[0]] = decodeURIComponent(item[1]);
    }, this);
  }
  this.raw = encodeParamaters(this);
}

QueryPars.prototype = {
  getItem: function(key) {
    return this.values[key];
  },
  setItem: function(key, value) {
    this.values[key] = value;
    if (this.keys.indexOf(key) < 0) {
      this.keys.push(key);
    }
    this.raw = encodeParamaters(this);
    if (this.historyObj) {
      updateHistoryObj(this);
    }
    return this;
  },
  clone: function() {
    return new QueryPars(this.toString());
  },
  toString: function() {
    return this.raw;
  }
};

function statePopped() {
  QueryPars.current = new QueryPars(document.location.href.indexOf('?') < 0 ? '' : document.location.href.split('?')[1], window.history);
}

window.addEventListener('popstate', statePopped);
statePopped();

export { QueryPars as QueryParameters };
