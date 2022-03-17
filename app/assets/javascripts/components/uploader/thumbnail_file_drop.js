import { addDelegatedEvent } from '../../jslim/events';

function triggerFileReady(sender) {
  (sender || document).dispatchEvent(new CustomEvent('thumbnail_file_drop', {
    bubbles: true, cancelable: true
  }));
}

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab} = e.detail.data;

  const coverInput = el.querySelector('.thumbnail-upload-form input[type=file]');
  coverInput.addEventListener('change', event => {
    triggerFileReady(coverInput);
  });

  const detailsForm = el.querySelector('.details-form');
  el.addEventListener('video_file_drop', event => {
    detailsForm.dataset.needsCover = event.detail.data.needsCover;
  });
});
