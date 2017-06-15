(function() {
  let worker;
  $(() => {
    if (document.location.hash.indexOf('#comment_') == 0) {
      lookupComment(document.location.hash.split('_')[1]);
    }
    function scroller() {
      const top = window.scrollY;
      const width = window.innerWidth;
      if (top <= 200) banner.css('background-position', `top calc(50% + ${top * 0.5}px) ${width > 1300 ? 'left' : 'center'}, top calc(50% + ${top * 0.5}px) right`);
    }
    const banner = $('#banner');
    if (banner.length) {
      if (window.requestAnimationFrame) {
        function animator() {
          scroller();
          window.requestAnimationFrame(animator);
        }
        animator();
      } else {
        console.log('RequestAnimationFrame not supported. Using scroll instead');
        $(window).on('scroll', scroller);
      }
    }

    if (window.current_user && window.SharedWorker && (window.force_notifications || Boolean(localStorage.give_me_notifications))) {
      const doc_title = $('#document_title');
      let title = doc_title.text();
      worker = new SharedWorker('<%= asset_path("notifications.js") %>');
      worker.port.addEventListener('message', e => {
        if (e.data.command == 'feeds') {
          if (e.data.count > 0) {
            $('.notices-bell.feeds').html(`<i class="fa fa-globe" /><span>${e.data.count}</span>`);
          } else {
            $('.notices-bell.feeds').html('<i class="fa fa-globe" />');
          }
        } else if (e.data.command == 'notices') {
          $('.notices-bell.notices span:not(.invert)').remove();
          if (e.data.count > 0) {
            $('.notices-bell.notices i').after(`<span>${e.data.count}</span>`);
          }
        } else if (e.data.command == 'mail') {
          if (e.data.count > 0) {
            $('.notices-bell.notices').append(`<span class="invert">${e.data.count}</span>`);
          } else {
            $('.notices-bell.notices span.invert').remove();
          }
        }
        if (e.data.command == 'notices' || e.data.command == 'feeds' || e.data.command == 'mail') {
          if (!window_focused && e.data.count) {
            if (title.indexOf('*') !== 0) {
              title = `* ${title}`;
              doc_title.text(title);
            }
          } else {
            if (title.indexOf('*') == 0) {
              title = title.replace('* ', '');
              doc_title.text(title);
            }
          }
        }
      });
      $(window).on('focus', () => {
        if (title.indexOf('*') == 0) {
          title = title.replace('* ', '');
          doc_title.text(title);
        }
      });
      worker.port.start();
      worker.port.postMessage({
        command: 'connect',
        notices: $('.notices-bell.notices span').length ? parseInt($('.notices-bell.notices span').text()) : 0,
        feeds: $('.notices-bell.feeds span').length ? parseInt($('.notices-bell.feeds span').text()) : 0
      });
      window.onbeforeunload = function() {
        worker.port.postMessage({command: 'disconnect'});
        return null;
      };
    }
  });
}());
