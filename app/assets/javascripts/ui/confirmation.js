import { ajax } from '../utils/ajax.js';
import { paginator } from '../components/paginator.js';
import { Popup } from '../components/popup.js';

function createPopup(me, action) {
  var id = me[0].dataset.id;
  var callback = me[0].dataset.callback;
  var url = me[0].dataset.url;
  var msg = me[0].dataset.msg;
  
  return new Popup(me[0].dataset.title, me[0].dataset.icon, function() {
    var ok = $('<button class="button-fw green confirm">Yes</button>');
    var cancel = $('<button class="cancel button-fw blue" style="margin-left:20px;" type="button">No</button>');
    
    this.content.append('<div class="message_content"></div><div class="foot"></div>');
    this.content.messageContent = this.content.find('.message_content');
    
    if (msg) {
      this.content.messageContent.text(msg);
      this.content.messageContent.append('<br/><br/>');
    }
    this.content.messageContent.append('Are you sure you want to continue?');
    
    ok.on('click', function() {
      ajax.post(url, function(json) {
        if (action == 'remove') {
          var removeable = me.parents('.removeable');
          if (removeable.hasClass('repaintable')) {
            paginator.repaint(removeable.closest('.paginator'), json);
          } else {
            removeable.remove();
          }
          return;
        }
        
        if (json.ref) {
          return document.location.replace(json.ref);
        }
        if (callback && typeof window[callback] === 'function') {
          window[callback](id, json);
        }
      });
      popup.close();
    });
    
    cancel.on('click', function() {
      popup.close();
    });
    
    this.content.foot = this.content.find('.foot');
    this.content.foot.addClass('center');
    this.content.foot.append(ok);
    this.content.foot.append(cancel);
    this.setPersistent();
    this.setWidth(400);
    this.show();
  });
}

function createTemplatePopup(sender) {
  return new Popup(sender.dataset.title, sender.dataset.icon, function() {
    this.content.append(document.getElementById(sender.dataset.template).innerHTML);
    var self = this;
    this.content.find('button.cancel').on('click', function() {
      self.close();
    });
    this.setFixed();
    this.show();
  });
}

function init(me) {
  var action = me[0].dataset.action;
  var maxWidth = me[0].dataset.maxWidth;
  var popup;
  
  me.addClass('loaded');
  
  if (action == 'delete' || action == 'remove') {
    if (!popup) {
      popup = createPopup(me, action);
    } else {
      popup.show();
    }
  } else if (action == 'template') {
    if (!popup) {
      popup = createTemplatePopup(me[0]);
    } else {
      popup.show();
    }
  } else {
    popup = Popup.fetch(me[0].dataset.url, me[0].dataset.title, me[0].dataset.icon, me.hasClass('confirm-button-thin'), me[0].dataset.eventLoaded);
    popup.setPersistent();
  }
  if (popup && maxWidth) popup.content.css('max-width', maxWidth);
  me.on('click', function(e) {
    popup.show();
    e.preventDefault();
  });
}

$(document).on('click', '.confirm-button:not(.loaded)', function(e) {
  init($(this));
  e.preventDefault();
});
