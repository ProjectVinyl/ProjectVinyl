import { error } from './popup';
import { toBool } from '../utils/misc';
import { jSlim } from '../utils/jslim';

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
  
  function dispatchCallback(detail) {
    me.dispatchEvent(new CustomEvent('accept', {
      detail: detail,
      bubbles: true
    }));
  }
  
  jSlim.on(me, 'change', 'input', function() {
    handleFiles(this.files, allowMulti, type, function(f, title) {
      dispatchCallback({
        title: title.splice(0, title.length - 1).join('.'),
        mime: f.type,
        type: title[title.length - 1],
        data: f
      });
    });
  });
  
  if (me.parentNode.classList.contains('file-select-container')) {
    var options = me.parentNode.querySelector('.file-select-options');
    if (options) {
      jSlim.on(options, 'change', 'input', function(e) {
        if (this.dataset.action == 'erase') {
          if (this.checked) {
            let input = me.querySelector('input');
            input.value = '';
            dispatchCallback({}); // Deletion is handled by the server when this checkbox is set, since we can't easily erase a fileinput's value
            this.checked = false;
          }
        }
      });
    }
  }
  
  return me;
}

jSlim.ready(function() {
  jSlim.all('.file-select', function(f) {
    initFileSelect(f);
  });
});

export { initFileSelect };
