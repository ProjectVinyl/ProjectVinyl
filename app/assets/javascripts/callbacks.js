/**
 * Callback methods executed after certain actions.
 * i.e. When the banner selection dialog is opened
 */
import { uploadForm } from './utils/progressform';
import { addDelegatedEvent } from './jslim/events';
import { all } from './jslim/dom';
import { popupError } from './components/popup';

addDelegatedEvent(document, 'ajax:complete', 'form.js-edit-video', (e, sender) => {
  const data = e.detail.data;
  const source = sender.parentNode.querySelector('.normal.tiny-link a');
  
  sender.querySelector('.tag-editor').getTagEditorObj().reload(data.results);
  source.innerText = source.href = data.source;
});

addDelegatedEvent(document, 'loaded', '.js-banner-select', () => {
  const me = document.getElementById('banner-upload');
  const banner = document.getElementById('banner');
  
  me.querySelector('input[type="file"]').addEventListener('change', function(e) {
    e.preventDefault();
    uploadForm(this.closest('form'), {
      success: () => {
        banner.style.backgroundSize = 'cover';
        banner.style.backgroundImage = `url(${me.dataset.path}?${new Date().getTime()})`;
      }
    });
  });
});

addDelegatedEvent(document, 'submit', '.form.report form.async', (e, sender) => {
  e.preventDefault();
  e.stopImmediatePropagation(); // form.async
  uploadForm(sender, {
    progress: (message, fill, percentage) => {
      if (percentage >= 100) {
        message.innerHTML = '<i style="color: lightgreen; font-size: 50px;" class="fa fa-check"></i></br>Thank you! Your report will be addressed shortly.';
      }
    },
    error: (message, error) => {
      message.innerHTML = `<i style="color: red; font-size: 50px;" class="fa fa-times"></i><br>Error: ${error}<br>Please contact <a href="mailto://support@projectvinyl.net">support@projectvinyl.net</a> for assistance.`;
    }
  });
});

addDelegatedEvent(document, 'change', '.avatar.file-select', (e, target) => {
  e.preventDefault();
  uploadForm(e.target.closest('form'), {
    success: () => {
      const ext = e.target.files.length ? e.target.files[0].name.split('.').reverse()[0] : 'png';
      all('#login .avatar.small span, #avatar-upload .preview', el => {
        el.style.backgroundImage = `url(/avatar/${target.dataset.id}.${ext}?${new Date().getTime()})`;
      });
    }
  });
});
