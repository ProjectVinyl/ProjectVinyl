(function() {
  var grabber;
  var floater;
  
  function moveFloater(e) {
    floater.css('top', e.pageY - floater.parent().offset().top);
  }
  
  function reorder(target, id, index) {
    ajax.post('update/' + target, function() {
      
    }, true, {
      id: id, index: index
    });
  }
  
  function grab(target, container, item) {
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
    var originalIndex = parseInt(item.attr('data-index'));
    floater.addClass('floater');
    floater.css('top', item.offset().top);
    $doc.one('mouseup', function(e) {
      floater.remove();
      floater = null;
      reorder(target, item.attr('data-id'), item.attr('data-index'));
      container.removeClass('ordering');
      container.find('.grabbed').removeClass('grabbed');
      container.children(':not(.floater)').off('mouseover');
      e.preventDefault();
      e.stopPropagation();
      $(document).off('mousemove', moveFloater);
      container.children().each(function(i) {
        $(this).attr('data-index', i);
      });
    });
    $doc.on('mousemove', moveFloater);
    container.children(':not(.floater)').on('mouseover', function() {
      $(this).after(item);
      var index = parseInt($(this).attr('data-index'));
      if (index <= originalIndex) index++;
      item.attr('data-index', index);
    });
  }
  
  $(function() {
    $('.reorderable').each(function() {
      var orderable = $(this);
      var target = orderable.attr('data-target');
      orderable.find('.handle').on('mousedown', function(e) {
        var me = $(this).parent();
        grabber = function() {
          grab(target, orderable, me);
        };
        $(document).one('mousemove', grabber);
        e.preventDefault();
        e.stopPropagation();
      }).on('mouseup', '.reorderable .handle', function(e) {
        $(document).off('mousemove', grabber);
      });
    });
  });
  
  
  $doc.on('click', '.removeable .remove', function(e) {
    var me = $(this).parents('.removeable');
    if (me.hasClass('repaintable')) {
      ajax.post('delete/' + me.attr('data-target'), function(json) {
        paginator.repaint(me.closest('.paginator'), json);
      }, false, { id: me.attr('data-id') });
    } else {
      if (me.attr('data-target')) {
        ajax.post('delete/' + me.attr('data-target'), function() {
          me.remove();
        }, true, { id: me.attr('data-id') });
      } else {
        me.remove();
      }
    }
    e.preventDefault();
    e.stopPropagation();
  });
})();