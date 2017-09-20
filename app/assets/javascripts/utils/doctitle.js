
export function docTitle() {
  const title = document.getElementById('document_title');
  const me = {
    get: _ => title.innerText,
    set: text => title.innerText = text,
    change: changerFunc => changerFunc(me.get(), me.set),
    togglePrefix: on => {
      if (on) return me.addPrefix();
      me.removePrefix();
    },
    addPrefix: _ => {
      const text = me.get();
      if (text.indexOf('*') != 0) {
        me.set(`* ${text}`);
      }
    },
    removePrefix: _ => {
      const text = me.get();
      if (text.indexOf('*') == 0) {
        me.set(text.replace('* ', ''));
      }
    }
  };
  return me;
}

