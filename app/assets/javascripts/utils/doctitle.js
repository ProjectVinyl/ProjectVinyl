function docTitle() {
  var title = document.getElementById('document_title');
  var me = {
    get: function() {
      return title.innerText;
    },
    set: function(text) {
      title.innerText = text;
    },
    change: function(changerFunc) {
      changerFunc(me.get(), me.set);
    },
    togglePrefix: function(on) {
      if (on) {
        return me.addPrefix();
      }
      me.removePrefix();
    },
    addPrefix: function() {
      var text = me.get();
      if (text.indexOf('*') != 0) {
        me.set('* ' + text);
      }
    },
    removePrefix: function() {
      var text = me.get();
      if (text.indexOf('*') == 0) {
        me.set(text.replace('* ', ''));
      }
    }
  };
  return me;
}

export { docTitle };