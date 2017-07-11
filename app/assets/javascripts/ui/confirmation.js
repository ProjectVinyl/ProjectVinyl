import { ajax } from '../utils/ajax';
import { paginator } from '../components/paginator';
import { Popup } from '../components/popup';
import { jSlim } from '../utils/jslim';

function createPopup(me, action) {
  var id = me.dataset.id;
  var url = me.dataset.url;
  var msg = me.dataset.msg;
  
  return new Popup(me.dataset.title, me.dataset.icon, function() {
    this.content.innerHTML = '\
      <div class="message_content"></div>\
      <div class="foot center">\
        <button class="button-fw green confirm">Yes</button>\
        <button class="cancel button-fw blue" style="margin-left:20px;" type="button">No</button>\
      </div>';
    this.content.foot = this.content.querySelector('.foot');
    this.content.messageContent = this.content.querySelector('.message_content');
    
    if (msg) {
      this.content.messageContent.innerText = msg;
      this.content.messageContent.appendChild(document.createElement('BR'));
    }
    this.content.messageContent.innerHTML += 'Are you sure you want to continue?';
    
    this.confirm = function() {
      ajax.post(url).json(function(json) {
        if (action == 'remove') {
          var removeable = me.closest('.removeable');
          if (removeable.classList.contains('repaintable')) {
            paginator.repaint(removeable.closest('.paginator'), json);
          } else {
            removeable.parentNode.removeChild(removeable);
          }
          return;
        }

        me.dispatchEvent(new CustomEvent('ajax:complete', {
          detail: { data: json },
          bubbles: true,
          cancelable: true
        }));
        
        if (json.ref) {
          return document.location.replace(json.ref);
        }
      });
    };
    this.setPersistent();
    this.setWidth(400);
    this.show();
  });
}

function createTemplatePopup(sender) {
  return new Popup(sender.dataset.title, sender.dataset.icon, function() {
    this.content.innerHTML = document.getElementById(sender.dataset.template).innerHTML;
    this.setFixed();
    this.show();
  });
}

function init(me) {
  var action = me.dataset.action;
  var maxWidth = me.dataset.maxWidth;
  var popup;
  
  me.classList.add('loaded');
  
  if (action == 'delete' || action == 'remove') {
    if (!popup) {
      popup = createPopup(me, action);
    } else {
      popup.show();
    }
  } else if (action == 'template') {
    if (!popup) {
      popup = createTemplatePopup(me);
    } else {
      popup.show();
    }
  } else {
    popup = Popup.fetch(me.dataset.url, me.dataset.title, me.dataset.icon, me.classList.contains('confirm-button-thin'), me);
    popup.setPersistent();
  }
  if (popup && maxWidth) popup.setWidth(maxWidth);
  me.addEventListener('click', function(e) {
    popup.show();
    e.preventDefault();
  });
}

jSlim.on(document, 'click', '.confirm-button:not(.loaded)', function(e) {
  init(this);
  e.preventDefault();
});
