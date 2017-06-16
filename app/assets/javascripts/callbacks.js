/* Callback methods executed after certain actions.
 * i.e. When the banner selection ialogue is opened
 */


function loadBannerSelector() {
  var me = $('#banner-upload');
  var basePath = me[0].dataset.path;
  initFileSelect(me).on('accept', function(e) {
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
}

function editVideo(sender, data) {
  sender.find('.tag-editor')[0].getTagEditorObj().reload(data.results);
  sender.parent().find('.normal.tiny-link a').attr('href', data.source).text(data.source);
}

$(function() {
  /* Everything's ready, load latecomers
   * TODO: Remove this when there's no more envload stuff
   */
  $doc.trigger('envload');
});