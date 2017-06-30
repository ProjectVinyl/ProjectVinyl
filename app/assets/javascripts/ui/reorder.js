import { ajax } from '../utils/ajax.js';
import { paginator } from '../components/paginator.js';
import { jSlim } from '../utils/jslim.js';

var grabber;
var floater;

function moveFloater(e) {
  floater.css('top', e.pageY - floater.parent().offset().top);
}

function reorder(target, id, index) {
  ajax.post('update/' + target, {
    id: id, index: index
  }, function() { });
}

function grab(target, container, item) {
  var originalIndex = parseInt(item[0].dataset.index);
  
  container.addClass('ordering');
  container.find('.grabbed').removeClass('grabbed');
  floater = item.clone();
  item.addClass('grabbed');
  container.append(floater);
  
  var srcChilds = item.children();
  var dstChilds = floater.children();
  
  for (var i = 0; i < srcChilds.length; i++) {
    dstChilds.eq(i).css('width', srcChilds.eq(i).innerWidth());
  }
  
  floater.addClass('floater');
  floater.css('top', item.offset().top);
  $(document).one('mouseup', function(e) {
    floater.remove();
    floater = null;
    reorder(target, item[0].dataset.id, item[0].dataset.index);
    container.removeClass('ordering');
    container.find('.grabbed').removeClass('grabbed');
    container.children(':not(.floater)').off('mouseover');
    
    $(document).off('mousemove', moveFloater);
    container.children().each(function(i) {
      this.dataset.index = i;
    });
    
    e.preventDefault();
    e.stopPropagation();
  });
  $(document).on('mousemove', moveFloater);
  container.children(':not(.floater)').on('mouseover', function() {
    var index = parseInt(this.dataset.index);
    $(this).after(item);
    if (index <= originalIndex) index++;
    item.attr('data-index', index);
  });
}

jSlim.ready(function() {
  $('.reorderable').each(function() {
    var target = this.dataset.target;
    var orderable = $(this);
    orderable.find('.handle').on('mousedown', function(e) {
      var me = $(this).parent();
      grabber = function() {
        grab(target, orderable, me);
      };
      $(document).one('mousemove', grabber);
      e.preventDefault();
      e.stopPropagation();
    }).on('mouseup', '.reorderable .handle', function() {
      $(document).off('mousemove', grabber);
    });
  });
});

jSlim.on(document, 'click', '.removeable .remove', function(e) {
  var me = this.closest('.removeable');
  
  if (me.classList.contains('repaintable')) {
    return ajax.post('delete/' + me.dataset.target, {
      id: me.dataset.id
    }, function(json) {
      paginator.repaint(me.closest('.paginator'), json);
    });
  }
  
  if (me.dataset.target) {
    ajax.post('delete/' + me.dataset.target, {
      id: me.dataset.id
    }, function() {
      me.parentNode.removeChild(me);
    });
  } else {
    me.parentNode.removeChild(me);
  }
  e.preventDefault();
  e.stopPropagation();
});
