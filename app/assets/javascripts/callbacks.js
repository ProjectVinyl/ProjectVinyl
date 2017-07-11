/**
 * Callback methods executed after certain actions.
 * i.e. When the banner selection dialog is opened
 */

import { ajax } from './utils/ajax';
import { jSlim } from './utils/jslim';
import { initFileSelect } from './components/fileinput';
import { slideAcross } from './ui/slide';
import { error } from './components/popup';

jSlim.on(document, 'ajax:complete', 'form.js-edit-video', function(event) {
  const sender = this, data = event.detail.data;
  const source = sender.parentNode.querySelector('.normal.tiny-link a');

  sender.querySelector('.tag-editor').getTagEditorObj().reload(data.results);
  source.innerText = source.href = data.source;
});

jSlim.on(document, 'loaded', '.confirm-button.js-banner-select', function(event) {
  const me = document.getElementById('banner-upload');
  const banner = document.getElementById('banner');
  const basePath = me.dataset.path;

  initFileSelect(me).addEventListener('accept', function(e) {
    const form = this.closest('form');
    ajax.form(form, e, {
      success: function() {
        form.classList.remove('uploading');
        banner.style.backgroundSize = 'cover';
        banner.style.backgroundImage = 'url(' + basePath + '?' + new Date().getTime() + ')';
      }
    });
  });
});

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
  e.stopImmediatePropagation(); // form.async
});

jSlim.on(document, 'accept', '.avatar.file-select', function(event) {
  const { target, detail } = event;
  const form = event.target.closest('form');

  ajax.form(form, {
    success: function() {
      form.classList.remove('uploading');
      jSlim.all('#login .avatar.small span, #avatar-upload .preview', function(el) {
        el.style.backgroundImage = 'url(/avatar/' + target.dataset.id + '.' + detail.type + '?' + new Date().getTime() + ')';
      });
    }
  });
});
