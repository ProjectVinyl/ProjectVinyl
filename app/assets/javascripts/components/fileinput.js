import { jSlim } from '../utils/jslim';

function initFileSelect(me) {
  if (me.loaded) return;
  me.loaded = true;

  const fileInput = me.querySelector('input[type="file"]');
  
  if (me.parentNode.classList.contains('file-select-container')) {
    var options = me.parentNode.querySelector('.file-select-options');
    if (options) {
      jSlim.on(options, 'change', 'input', function(e) {
        if (this.dataset.action == 'erase' && this.checked) {
          fileInput.value = '';
          this.checked = false;
        }
      });
    }
  }
}

jSlim.ready(() => {
  jSlim.all('.file-select', function(f) {
    initFileSelect(f);
  });
});

export { initFileSelect };
