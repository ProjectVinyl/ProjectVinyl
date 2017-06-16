(function() {
  function initWorker() {
    var docTitle = $('#document_title');
    var title = docTitle.text();
    var worker = new SharedWorker('<%= asset_path("notifications.js") %>');
    
    worker.port.addEventListener('message', function(e) {
      if (e.data.command == 'feeds') {
        if (e.data.count > 0) {
          $('.notices-bell.feeds').html('<i class="fa fa-globe" /><span>' + e.data.count + '</span>');
        } else {
          $('.notices-bell.feeds').html('<i class="fa fa-globe" />');
        }
      } else if (e.data.command == 'notices') {
        $('.notices-bell.notices span:not(.invert)').remove();
        if (e.data.count > 0) {
          $('.notices-bell.notices i').after('<span>' + e.data.count + '</span>');
        }
      } else if (e.data.command == 'mail') {
        if (e.data.count > 0) {
          $('.notices-bell.notices').append('<span class="invert">' + e.data.count + '</span>');
        } else {
          $('.notices-bell.notices span.invert').remove();
        }
      }
      if (e.data.command == 'notices' || e.data.command == 'feeds' || e.data.command == 'mail') {
        if (!windowFocused && e.data.count) {
          if (title.indexOf('*') !== 0) {
            title = '* ' + title;
            docTitle.text(title);
          }
        } else {
          if (title.indexOf('*') == 0) {
            title = title.replace('* ', '');
            docTitle.text(title);
          }
        }
      }
    });
    $(window).on('focus', function() {
      if (title.indexOf('*') == 0) {
        title = title.replace('* ', '');
        docTitle.text(title);
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
  
  $(function() {
    if (window.current_user && window.SharedWorker && (window.force_notifications || !!localStorage.give_me_notifications)) {
      initWorker();
    }
  });
})();