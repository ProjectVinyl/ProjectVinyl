import { addDelegatedEvent } from '../../jslim/events';
import { validateVideoForm } from './video_form_validations';
import { UploadQueue } from './queue';
import { ofAll, initProgressor } from './progress_bar_callback';

const UPLOADING_QUEUE = new UploadQueue();

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab} = e.detail.data;
  const detailsForm = el.querySelector('.details-form');
  const thumbnailForm = el.querySelector('.thumbnail-form');

  const validationCallback = () => validateVideoForm(detailsForm);

  tab.querySelector('i.fa-undo').addEventListener('click', () => {
    thumbnailForm.classList.remove('uploading', 'error', 'pending');
  });

  const coverInput = el.querySelector('#cover-upload input[type=file]');
  thumbnailForm.addEventListener('submit', event => {
    if (thumbnailForm.save) {
      thumbnailForm.save.disabled = true;
    }
    const progressor = ofAll([initProgressor(tab, thumbnailForm), {
      complete(data) {
        if (!data.success) {
          detailsForm.dataset.hasCover = false;
          detailsForm.dataset.uploadError = data.error.title + ': ' + data.error.description;
        }
        validationCallback();
      }
    }]);
    progressor.form = thumbnailForm;
    UPLOADING_QUEUE.enqueue(progressor);
    validationCallback();
    event.preventDefault();
  });
  coverInput.addEventListener('change', () => {
    thumbnailForm.submit();
  });
  el.addEventListener('video_file_drop', event => {
    const {needsCover, mime, file, id, params} = event.detail.data;

    detailsForm.dataset.needsCover = needsCover;
  });
});
