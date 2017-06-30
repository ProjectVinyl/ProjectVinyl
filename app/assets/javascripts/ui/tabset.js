import { ajax } from '../utils/ajax.js';

function focusTab(me) {
  if (!me.hasClass('selected') && me[0].dataset.target) {
    var other = me.parent().find('.selected');
    if (other.length) {
      other.removeClass('selected');
      $('div[data-tab="' + other[0].dataset.target + '"]').removeClass('selected').trigger('tabblur');
    }
    me.addClass('selected');
    $('div[data-tab="' + me[0].dataset.target + '"]').addClass('selected').trigger('tabfocus');
  }
}

$(document).on('click', '.tab-set > li.button:not([data-disabled])', function() {
  focusTab($(this));
});

$(document).on('click', '.tab-set > li.button i.fa-close', function(e) {
  var me = $(this.parentNode);
  $('div[data-tab="' + me[0].dataset.target + '"]').remove();
  me.addClass('hidden');
  
  setTimeout(function() {
    me.remove();
  }, 25);
  
  focusTab(me.parent().find('li.button:not([data-disabled]):not(.hidden)[data-target]').first());
  
  e.preventDefault();
  e.stopPropagation();
});

$(document).on('click', '.tab-set.async a.button:not([data-disabled])', function(e) {
  var me = $(this);
  if (!me.hasClass('selected')) {
    var parent = this.parentNode;
    var other = $(parent).find('.selected');
    var holder = $('.tab[data-tab=' + parent.dataset.target + ']');
    
    other.removeClass('selected');
    me.addClass('selected');
    holder.addClass('waiting');
    
    ajax.get(parent.dataset.url, function(json) {
      holder.html(json.content);
      holder.removeClass('waiting');
    }, {
      type: this.dataset.target, page: this.dataset.page || 0
    });
  }
  e.preventDefault();
});

export { focusTab };
