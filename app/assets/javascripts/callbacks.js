/**
 * Callback methods executed after certain actions.
 * i.e. When the banner selection dialog is opened
 */
import { uploadForm } from './utils/progressform';
import { jSlim } from './utils/jslim';
import { slideAcross } from './ui/slide';
import { popupError } from './components/popup';

jSlim.on(document, 'ajax:complete', 'form.js-edit-video', function(event) {
  const sender = this, data = event.detail.data;
  const source = sender.parentNode.querySelector('.normal.tiny-link a');
  
  sender.querySelector('.tag-editor').getTagEditorObj().reload(data.results);
  source.innerText = source.href = data.source;
});

jSlim.on(document, 'loaded', '.js-banner-select', function(event) {
  const me = document.getElementById('banner-upload');
  const banner = document.getElementById('banner');
  
  me.querySelector('input[type="file"]').addEventListener('change', function(e) {
    uploadForm(this.closest('form'), e, {
      success: function() {
        this.classList.remove('uploading');
        banner.style.backgroundSize = 'cover';
        banner.style.backgroundImage = 'url(' + me.dataset.path + '?' + new Date().getTime() + ')';
      }
    });
  });
});

jSlim.on(document, 'click', '.form.report input[data-to], .form.report button.goto.right', function() {
  var required = this.closest('.group').querySelectorAll('input[data-required]');
  if (required.length) {
    for (var i = 0; i < required.length; i++) {
      if (required.value != required.dataset.required && (required.getAttribute('type') !== 'checkbox' || !!required.checked != !!required.dataset.required)) {
        popupError('One or more required fields need to be filled in.');
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
  uploadForm(this, e, {
    progress: function(message, fill, percentage) {
      if (percentage >= 100) {
        message.innerHTML = '<i style="color: lightgreen; font-size: 50px;" class="fa fa-check"></i></br>Thank you! Your report will be addressed shortly.';
      }
    },
    success: function() {
      this.classList.remove('uploading');
    },
    error: function(message, msg) {
      this.classList.remove('uploading');
      message.style.marginLeft = '';
      message.innerHTML = '<i style="color: red; font-size: 50px;" class="fa fa-times"></i><br>Error: ' + msg + '<br>Please contact <a href="mailto://support@projectvinyl.net">support@projectvinyl.net</a> for assistance.';
    }
  });
  e.stopImmediatePropagation(); // form.async
});

jSlim.on(document, 'change', '.avatar.file-select', function(e) {
  const { target, detail } = event; // TODO: detail is not used
  const form = target.closest('form');
  const title = target.files.length ? target.files[0].name.split('.') : []; // Provided by detail?
  const fileSelect = this;
  
  uploadForm(form, event, {
    success: function() {
      this.classList.remove('uploading');
      jSlim.all('#login .avatar.small span, #avatar-upload .preview', function(el) {
        el.style.backgroundImage = 'url(/avatar/' + fileSelect.dataset.id + '.' + title[title.length - 1] + '?' + new Date().getTime() + ')';
      });
    }
  });
});
