const initFileSelect = (function() {
  function validateTypes(type, file) {
    if (type == 'image') {
      return Boolean(file.type.match(/image\//));
    } else if (type == 'a/v') {
      return Boolean(file.type.match(/(audio|video)\//));
    }
    return false;
  }

  function renderPreview(me, file) {
    const preview = me.find('.preview');
    const img = preview[0];
    if (img.src) URL.revokeObjectURL(img.src);
    img.src = URL.createObjectURL(file);
    preview.css('background-image', `url(${img.src})`);
  }

  function handleFiles(files, multi, type, callback) {
    let accepted = 0;
    for (let i = 0; i < files.length; i++) {
      if (validateTypes(type, files[i])) {
        callback(files[i], files[i].name.split('.'));
        accepted++;
      }
      if (!multi) break;
    }
    if (accepted == 0 && (files.length == 1 || !multi)) {
      return error('File type not surrorted. Please try again.');
    }
  }

  return function(me) {
    const type = me.attr('data-type');
    const allowMulti = toBool(me.attr('allow-multi'));
    const input = me.find('input').first();
    input.on('click', e => {
      e.stopPropagation();
    });
    me.on('dragover dragenter', () => {
      me.addClass('drag');
    }).on('dragleave drop', () => {
      me.removeClass('drag');
    });
    if (me.hasClass('image-selector') && window.FileReader) {
      input.on('change', () => {
        handleFiles(input[0].files, allowMulti, type, (f, title) => {
          renderPreview(me, f);
          const ext = title[title.length - 1];
          me.trigger('accept', {mime: f.type, type: ext});
        });
      });
    } else {
      input.on('change', () => {
        handleFiles(input[0].files, allowMulti, type, (f, title) => {
          const ext = title[title.length - 1];
          title = title.splice(0, title.length - 1).join('.');
          me.trigger('accept', {title, mime: f.type, type: ext, data: f});
        });
      });
    }
    return me;
  };
}());

$(() => {
  $('.file-select').each(function() {
    initFileSelect($(this));
  });
});
