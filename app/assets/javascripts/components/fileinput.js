import { error } from './popup.js';
import { toBool } from '../utils/misc.js';

function validateTypes(type, file) {
  switch (type) {
    case 'image':
      return !!file.type.match(/image\//);
    case 'a/v':
      return !!file.type.match(/(audio|video)\//);
    default:
      return false;
  }
}

function renderPreview(me, file) {
  const img = me.querySelector('.preview');

  if (img.src) URL.revokeObjectURL(img.src);
  img.src = URL.createObjectURL(file);
  img.style.backgroundImage = `url(${img.src})`;
}

function handleFiles(files, multi, type, callback) {
  // Only accept the first file in this case
  if (!multi) files = [files[0]];
  let accepted = 0;

  [].forEach.call(files, file => {
    if (validateTypes(type, file)) {
      callback(file, file.name.split('.'));
      ++accepted;
    }
  });

  // If a single-file upload wasn't accepted...
  if (accepted === 0 && files.length === 1) {
    return error('File type not surrorted. Please try again.');
  }
}

function initFileSelect(me) {
  const type = me.dataset.type;
  const allowMulti = toBool(me.getAttribute('allow-multi'));
  const input = me.querySelector('input');

  // ?
  input.addEventListener('click', e => e.stopPropagation());

  function enterDrag() { me.classList.add('drag'); }
  function leaveDrag() { me.classList.remove('drag'); }

  me.addEventListener('dragover', enterDrag);
  me.addEventListener('dragenter', enterDrag);
  me.addEventListener('dragleave', leaveDrag);
  me.addEventListener('drop', leaveDrag);

  if (me.classList.contains('image-selector')) {
    input.addEventListener('change', () => {
      handleFiles(input.files, allowMulti, type, (f, title) => {
        renderPreview(me, f);
        $(me).trigger('accept', {
          mime: f.type,
          type: title[title.length - 1]
        });
      });
    });
  } else {
    input.addEventListener('change', () => {
      handleFiles(input.files, allowMulti, type, (f, title) => {
        $(me).trigger('accept', {
          title: title.splice(0, title.length - 1).join('.'),
          mime: f.type,
          type: title[title.length - 1],
          data: f
        });
      });
    });
  }

  return me;
}

function setupFileSelects() {
  [].forEach.call(document.querySelectorAll('.file-select'), f => initFileSelect(f));
}

if (document.readyState !== 'loading') setupFileSelects();
else document.addEventListener('DOMContentLoaded', setupFileSelects);

export { initFileSelect };
