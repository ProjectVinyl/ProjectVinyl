/*
 * Callback methods executed after certain actions.
 * i.e. When the banner selection dialog is opened
 */

import { ajax } from './utils/ajax';
import { jSlim } from './utils/jslim';
import { initFileSelect } from './components/fileinput';
import { slideAcross } from './ui/slide';
import { error } from './components/popup';

const Callbacks = {
  callbackFunctions: {
    editVideo: function(sender, data) {
      sender.find('.tag-editor')[0].getTagEditorObj().reload(data.results);
      var source = sender[0].parentNode.querySelector('.normal.tiny-link a');
      source.innerText = source.href = data.source;
    },
    loadBannerSelector: function() {
      var me = document.getElementById('banner-upload');
      var banner = document.getElementById('banner');
      var basePath = me.dataset.path;
      initFileSelect(me).addEventListener('accept', function(e) {
        var form = this.closest('form');
        ajax.form(form, e, {
          success: function() {
            form.classList.remove('uploading');
            banner.style.backgroundSize = 'cover';
            banner.style.backgroundImage = 'url(' + basePath + '?' + new Date().getTime() + ')';
          }
        });
      });
    },
    loadReporter: function() {
      jSlim.on(document, 'click', '.form.report input[data-to], .form.report button.goto.right', function() {
        var required = this.closest('.group').querySelectorAll('input[data-required]');
        if (required.length) {
          for (var i = 0; i < required.length; i++) {
            if (required.value != required.dataset.required && (required.getAttribute('type') !== 'checkbox' || !!required.checked != !!required.dataset.required)) {
              error('One or more required fields need to be filled in.');
              required.focus();
              return;
            }
          }
        }
        slideAcross(this, 1);
      });
      jSlim.on(document, 'click', '.form.report button.goto.left', function() {
        slideAcross(this, -1);
      });
      jSlim.on(document, 'submit', '.form.report form.async', function(e) {
        var self = this;
        ajax.form(this, e, {
          progress: function(e, message, fill, percentage) {
            if (percentage >= 100) {
              message.innerHTML = '<i style="color: lightgreen; font-size: 50px;" class="fa fa-check"></i></br>Thank you! Your report will be addressed shortly.';
            }
          },
          success: function() {
            self.classList.remove('uploading');
          },
          error: function(message, error, msg) {
            self.classList.remove('uploading');
            message.style.marginLeft = '';
            message.innerHTML = '<i style="color: red; font-size: 50px;" class="fa fa-times"></i><br>' + error + ': ' + msg + '<br>Please contact <a href="mailto://support@projectvinyl.net">support@projectvinyl.net</a> for assistance.';
          }
        });
      });
    },
    changeAvatar: function(sender, data) {
      var form = sender.closest('form');
      ajax.form(form, {
        success: function() {
          form.classList.remove('uploading');
          jSlim.all('#login .avatar.small span, #avatar-upload .preview', function(el) {
            el.style.backgroundImage = 'url(/avatar/' + sender.dataset.id + '.' + data.type + '?' + new Date().getTime() + ')';
          });
        }
      });
    }
  },
  execute: function(name, params) {
    if (name && typeof this.callbackFunctions[name] === 'function') {
      this.callbackFunctions[name].apply(window, params);
      return true;
    }
  }
};

export { Callbacks };
