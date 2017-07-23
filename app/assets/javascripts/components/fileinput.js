import { jSlim } from '../utils/jslim';

jSlim.on(document, 'change', '.file-select-options input', function() {
  const fileInput = this.closest('.file-select-container').querySelector('input[type="file"]');
  
  if (this.dataset.action === 'erase' && this.checked) {
    fileInput.value = '';
    fileInput.dispatchEvent(new CustomEvent('change', { bubbles: true, cancelable: true }));
    this.checked = false;
  }
});

jSlim.on(document, 'change', '.file-select input[type="file"]', function(event) {
  const fileSelect = event.target.closest('.file-select');
  const preview = fileSelect.querySelector('.preview');
  
  if (!preview) return;
  if (preview.src) URL.revokeObjectURL(preview.src);
  preview.src = URL.createObjectURL(this.files[0]);
  preview.style.backgroundImage = 'url(' + preview.src + ')';
});
