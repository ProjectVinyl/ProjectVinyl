import { error } from './popup.js';

function validateTypes(type, file) {
  if (type == 'image') {
    return !!file.type.match(/image\//);
  }
  if (type == 'a/v') {
    return !!file.type.match(/(audio|video)\//);
  }
  return false;
}

function renderPreview(me, file) {
  var preview = me.find('.preview');
  var img = preview[0];
  if (img.src) URL.revokeObjectURL(img.src);
  img.src = URL.createObjectURL(file);
  preview.css('background-image', 'url(' + img.src + ')');
}

function handleFiles(files, multi, type, callback) {
  var accepted = 0;
  each(files, function() {
    if (validateTypes(type, this)) {
      callback(this, this.name.split('.'));
      accepted++;
    }
    if (!multi) return false;
  });
  if (accepted == 0 && (files.length == 1 || !multi)) {
    return error('File type not surrorted. Please try again.');
  }
}

function initFileSelect(me) {
  var type = me.attr('data-type');
  var allowMulti = toBool(me.attr('allow-multi'));
  var input = me.find('input').first();
  input.on('click', function(e) {
    e.stopPropagation();
  });
  me.on('dragover dragenter', function() {
    me.addClass('drag');
  }).on('dragleave drop', function() {
    me.removeClass('drag');
  });
  if (me.hasClass('image-selector') && window.FileReader) {
    input.on('change', function() {
      handleFiles(input[0].files, allowMulti, type, function(f, title) {
        renderPreview(me, f);
        me.trigger('accept', {
          mime: f.type,
          type: title[title.length - 1]
        });
      });
    });
  } else {
    input.on('change', function() {
      handleFiles(input[0].files, allowMulti, type, function(f, title) {
        me.trigger('accept', {
          title: title.splice(0, title.length - 1).join('.'),
          mime: f.type,
          type: title[title.length - 1],
          data: f
        });
      });
    });
  }
  return me;
};

$(function() {
  $('.file-select').each(function() {
    initFileSelect($(this));
  });
});

export { initFileSelect };
