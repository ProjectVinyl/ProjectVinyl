import { addDelegatedEvent } from '../../jslim/events';
import { all } from '../../jslim/dom';
import { validateVideoForm } from './video_form_validations';
import { UploadQueue } from './queue';
import { ofAll, initProgressor } from './progress_bar_callback';

const UPLOADING_QUEUE = new UploadQueue();

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab} = e.detail.data;
  const detailsForm = el.querySelector('.details-form');

  tab.querySelector('i.fa-undo').addEventListener('click', () => {
    all(el, '.thumbnail-form', form => {
      form.classList.remove('uploading', 'error', 'pending');
    });
  });

  const validationCallback = () => validateVideoForm(detailsForm);

  function submit(event) {
    event.preventDefault();

    const form = event.target.closest('form');
    if (form.save) {
      form.save.disabled = true;
    }
    const progressor = ofAll([initProgressor(tab, form), {
      complete(data) {
        if (!data.success) {
          detailsForm.dataset.hasCover = false;
          detailsForm.dataset.uploadError = data.error.title + ': ' + data.error.description;
        } else {
          detailsForm.dataset.hasCover = true;
        }
        validationCallback();
      }
    }]);
    progressor.form = form;
    UPLOADING_QUEUE.enqueue(progressor);
    validationCallback();
  }

  el.addEventListener('thumbnail_file_drop', submit);
  addDelegatedEvent(el, 'submit', '.thumbnail-form', submit);
});
