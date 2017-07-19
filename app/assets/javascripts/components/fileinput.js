import { jSlim } from '../utils/jslim';

jSlim.on(document, 'change', '.file-select-options input', function() {
  const fileInput = this.closest('.file-select-container').querySelector('input[type="file"]');
  
  if (this.dataset.action === 'erase' && this.checked) {
    fileInput.value = '';
    fileInput.dispatchEvent(new CustomEvent('change', { bubbles: true, cancelable: true }));
    this.checked = false;
  }
});
