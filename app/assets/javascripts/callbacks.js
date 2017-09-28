/**
 * Callback methods executed after certain actions.
 */
import { uploadForm } from './utils/progressform';
import { addDelegatedEvent } from './jslim/events';
import { all } from './jslim/dom';

addDelegatedEvent(document, 'ajax:complete', 'form.js-edit-video', (e, sender) => {
  const data = e.detail.data;
  const source = sender.parentNode.querySelector('.normal.tiny-link a');
  sender.querySelector('.tag-editor').getTagEditorObj().reload(data.results);
  source.innerText = source.href = data.source;
});

addDelegatedEvent(document, 'ajax:complete', 'form.js-banner-select', (e, target) => {
  const me = document.querySelector('#banner-upload');
  const banner = document.querySelector('#banner .banner-background');
  const erase = target.querySelector('input[name="erase"]');
  banner.style.background = erase.checked ? '' : `url(${me.dataset.path}?${new Date().getTime()}) center center/cover #000`;
});

addDelegatedEvent(document, 'submit', '.form.report form', (e, sender) => {
  uploadForm(sender, {
    success: (data, message) => {
      message.innerHTML = '<i style="color: lightgreen; font-size: 50px;" class="fa fa-check"></i></br>Thank you! Your report will be addressed shortly.';
    },
    error: (error, message) => {
      message.innerHTML = `<i style="color: red; font-size: 50px;" class="fa fa-times"></i><br>Error: ${error}<br>Please contact <a href="mailto://support@projectvinyl.net">support@projectvinyl.net</a> for assistance.`;
    }
  }, e);
});

addDelegatedEvent(document, 'ajax:complete', 'form.js-avatar-select', (e, target) => {
  const input = target.querySelector('.avatar.file-select input');
  const ext = input.files.length ? input.files[0].name.split('.').reverse()[0] : 'png';
  const img = `url(/avatar/${target.dataset.id}.${ext}?${new Date().getTime()})`;
  all('#login .avatar.small span, #avatar-upload .preview', el => el.style.backgroundImage = img);
});
