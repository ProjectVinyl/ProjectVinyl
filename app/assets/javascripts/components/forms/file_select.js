import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'change', '.file-select-options input', (e, target) => {
  const fileInput = target.closest('.file-select-container').querySelector('input[type="file"]');
  
  if (target.dataset.action === 'erase' && target.checked) {
    fileInput.value = '';
    fileInput.dispatchEvent(new CustomEvent('change', { bubbles: true, cancelable: true }));
    target.checked = false;
  }
});

addDelegatedEvent(document, 'change', '.file-select input[type="file"]', (event, target) => {
  const fileSelect = event.target.closest('.file-select');
  const preview = fileSelect.querySelector('.preview');
  
  if (!preview) return;
  if (preview.src) URL.revokeObjectURL(preview.src);

  preview.src = target.files.length ? URL.createObjectURL(target.files[0]) : '';
  preview.style.backgroundImage = `url(${preview.src})`;
});
