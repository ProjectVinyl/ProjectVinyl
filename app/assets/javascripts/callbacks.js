/*
 * Callback methods executed after certain actions.
 * i.e. When the banner selection dialog is opened
 */

import { ajax } from './utils/ajax.js';
import { initFileSelect } from './components/fileinput.js';

// app/views/artist/view.html.erb
window.loadBannerSelector = function loadBannerSelector() {
  var me = $('#banner-upload');
  var basePath = me[0].dataset.path;
  initFileSelect(me[0]);
  $(me).on('accept', function(e) {
    ajax.form($(this).closest('form'), e, {
      success: function() {
        this.removeClass('uploading');
        $('#banner').css({
          'background-size': 'cover',
          'background-image': 'url(' + basePath + '?' + new Date().getTime() + ')'
        });
      }
    });
  });
};

// app/views/video/_video.erb
window.editVideo = function editVideo(sender, data) {
  sender.find('.tag-editor')[0].getTagEditorObj().reload(data.results);
  sender.parent().find('.normal.tiny-link a').attr('href', data.source).text(data.source);
};
