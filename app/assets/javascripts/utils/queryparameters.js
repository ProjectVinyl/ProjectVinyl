function encodeParamaters(queryPars) {
  return queryPars.keys.map(k => `${k}=${encodeURIComponent(queryPars.values[k])}`).join('&');
}

function updateHistoryObj(queryPars) {
  if (queryPars.historyObj.pushState) {
    var newUrl = document.location.href.split('?')[0] + '?' + queryPars.toString();
    if (newUrl != document.location.href) {
      window.history.pushState({
        path: newUrl
      }, '', newUrl);
    }
  }
}

function QueryPars(raw, historyObj) {
  var self = this;
  this.keys = [];
  this.values = {};
  this.historyObj = historyObj;
  if (raw.indexOf('&') > -1) {
    raw.split('&').forEach(pair => {
      var item = pair.split('=');
      if (item.length < 2) item.push('');
      if (self.keys.indexOf(item[0]) < 0) {
        self.keys.push(item[0]);
      }
      self.values[item[0]] = decodeURIComponent(item[1]);
    });
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

QueryPars.current = new QueryPars(document.location.href.indexOf('?') < 0 ? '' : document.location.href.split('?')[1], window.history);

export { QueryPars as QueryParameters };
