(function() {
  let grabber;
  let floater;

  function moveFloater(e) {
    floater.css('top', e.pageY - floater.parent().offset().top);
  }

  function reorder(target, id, index) {
    ajax.post(`update/${target}`, () => {}, true, {
      id, index
    });
  }

  function grab(target, container, item) {
    container.addClass('ordering');
    container.find('.grabbed').removeClass('grabbed');
    floater = item.clone();
    item.addClass('grabbed');
    container.append(floater);
    const srcChilds = item.children();
    const dstChilds = floater.children();
    for (let i = 0; i < srcChilds.length; i++) {
      dstChilds.eq(i).css('width', srcChilds.eq(i).innerWidth());
    }
    const originalIndex = parseInt(item.attr('data-index'));
    floater.addClass('floater');
    floater.css('top', item.offset().top);
    $doc.one('mouseup', e => {
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
      let index = parseInt($(this).attr('data-index'));
      if (index <= originalIndex) index++;
      item.attr('data-index', index);
    });
  }

  $(() => {
    $('.reorderable').each(function() {
      const orderable = $(this);
      const target = orderable.attr('data-target');
      orderable.find('.handle').on('mousedown', function(e) {
        const me = $(this).parent();
        grabber = function() {
          grab(target, orderable, me);
        };
        $(document).one('mousemove', grabber);
        e.preventDefault();
        e.stopPropagation();
      }).on('mouseup', '.reorderable .handle', e => {
        $(document).off('mousemove', grabber);
      });
    });
  });

  $doc.on('click', '.removeable .remove', function(e) {
    const me = $(this).parents('.removeable');
    if (me.hasClass('repaintable')) {
      ajax.post(`delete/${me.attr('data-target')}`, json => {
        paginator.repaint(me.closest('.paginator'), json);
      }, false, { id: me.attr('data-id') });
    } else {
      if (me.attr('data-target')) {
        ajax.post(`delete/${me.attr('data-target')}`, () => {
          me.remove();
        }, true, { id: me.attr('data-id') });
      } else {
        me.remove();
      }
    }
    e.preventDefault();
    e.stopPropagation();
  });
}());
