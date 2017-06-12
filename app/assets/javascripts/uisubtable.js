$(function() {
  function sizeSpannedBlocks() {
    $('.row.row-spanned > .content').each(function() {
      var me = $(this);
      me.parent().css('height', me.children().height());
    });
  }
  if ($('.row.row-spanned').length) {
    $('.state-toggle').on('toggle', sizeSpannedBlocks);
    $('.row.row-spanned input, .row.row-spanned textarea').on('keyup', sizeSpannedBlocks);
    $(window).on('resize', sizeSpannedBlocks);
    $('.row.row-spanned .tag-editor').on('tagschange', sizeSpannedBlocks);
  }
});