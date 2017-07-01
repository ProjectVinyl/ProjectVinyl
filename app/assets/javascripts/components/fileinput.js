import { error } from './popup.js';
import { toBool } from '../utils/misc.js';
import { jSlim } from '../utils/jslim.js';

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
  var img = me.querySelector('.preview');
  
  if (img.src) URL.revokeObjectURL(img.src);
  img.src = URL.createObjectURL(file);
  img.style.backgroundImage = 'url(' + img.src + ')';
}

function handleFiles(files, multi, type, callback) {
  // Only accept the first file in this case
  if (!multi) files = [files[0]];
  let accepted = 0;
  
  [].forEach.call(files, function(file) {
    if (validateTypes(type, file)) {
      callback(file, file.name.split('.'));
      accepted++;
    }
  });
  
  // If a single-file upload wasn't accepted...
  if (accepted === 0 && files.length === 1) {
    return error('File type not supported. Please try again.');
  }
}

function initFileSelect(me) {
  if (me.loaded) return;
  me.loaded = true;
  
  const type = me.dataset.type;
  const allowMulti = toBool(me.getAttribute('allow-multi'));
  const input = me.querySelector('input');
  
  // Don't let the clicks escape; they might get out and replicate.
  // (prevents triggering handlers higher up in the dom)
  input.addEventListener('click', function(e) {
    e.stopPropagation()
  });
  
  function enterDrag() {
    me.classList.add('drag');
  }
  function leaveDrag() {
    me.classList.remove('drag');
  }
  
  me.addEventListener('dragover', enterDrag);
  me.addEventListener('dragenter', enterDrag);
  me.addEventListener('dragleave', leaveDrag);
  me.addEventListener('drop', leaveDrag);
  
  if (me.classList.contains('image-selector')) {
    input.addEventListener('change', function() {
      handleFiles(input.files, allowMulti, type, function(f, title) {
        renderPreview(me, f);
        me.dispatchEvent(new CustomEvent('accept', {
          detail: {
            mime: f.type,
            type: title[title.length - 1]
          },
          bubbles: true
        }));
      });
    });
  } else {
    input.addEventListener('change', function(e) {
      handleFiles(input.files, allowMulti, type, function(f, title) {
        me.dispatchEvent(new CustomEvent('accept', {
          detail: {
            title: title.splice(0, title.length - 1).join('.'),
            mime: f.type,
            type: title[title.length - 1],
            data: f
          },
          bubbles: true
        }));
      });
    });
  }
  
  return me;
}

jSlim.ready(function() {
  jSlim.all('.file-select', function(f) {
    initFileSelect(f);
  });
});

export { initFileSelect };
