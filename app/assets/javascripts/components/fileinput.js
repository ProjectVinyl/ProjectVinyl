import { jSlim } from '../utils/jslim';

function initFileSelect(me) {
  if (me.loaded) return;
  me.loaded = true;

  const fileInput = me.querySelector('input[type="file"]');
  
  function dispatchCallback(detail) {
    me.dispatchEvent(new CustomEvent('accept', { detail, bubbles: true }));
  }

  fileInput.addEventListener('change', () => {
    [].forEach.call(fileInput.files, file => {
      const title = file.name.split('.');
      dispatchCallback({
        title: title.splice(0, title.length - 1).join('.'),
        mime: file.type,
        type: title[title.length - 1],
        data: file
      });
    });
  });
  
  if (me.parentNode.classList.contains('file-select-container')) {
    var options = me.parentNode.querySelector('.file-select-options');
    if (options) {
      jSlim.on(options, 'change', 'input', function(e) {
        if (this.dataset.action == 'erase' && this.checked) {
          fileInput.value = '';
          dispatchCallback({}); // Deletion is handled by the server when this checkbox is set, since we can't easily erase a fileinput's value
          this.checked = false;
        }
      });
    }
  }
  
  return me;
}

jSlim.ready(() => {
  jSlim.all('.file-select', function(f) {
    initFileSelect(f);
  });
});

export { initFileSelect };
