/* Callback methods executed after certain actions.
 * i.e. When the banner selection ialogue is opened
 */


function loadBannerSelector() {
  var me = $('#banner-upload');
  var base_path = me.attr('data-base-path');
  initFileSelect(me).on('accept', function(e, file) {
    var form = $(this).closest('form');
    ajax.form(form, e, {
      success: function() {
        form.removeClass('uploading');
        var av = $('#banner');
        av.css({
          'background-size': 'cover',
          'background-image': 'url(' + base_path + '?' + new Date().getTime() + ')'
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