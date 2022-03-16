import { ready, addDelegatedEvent } from '../../jslim/events';
import { UploadQueue } from './queue';
import { ofAll, initProgressor } from './progress_bar_callback';

const UPLOADING_QUEUE = new UploadQueue();

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab,id} = e.detail.data;
  const detailsForm = el.querySelector('.details-form');

  tab.querySelector('i.fa-undo').addEventListener('click', () => {
    tab.classList.remove('uploading', 'error', 'pending');
    detailsForm.classList.remove('uploading', 'error', 'pending');
  });

  detailsForm.addEventListener('submit', event => {
    const progressor = ofAll([initProgressor(tab, detailsForm), {
      complete(data) {
        if (!data.success) {
          detailsForm.dataset.uploadError = data.error.title + ': ' + data.error.description;
        }
        if (data.discard) {
          tab.querySelector('i.fa-close').click();
        }

        if (data.ref) {
          el.innerHTML = `Uploading Complete. You can see your new video over <a target="_blank" href="${data.ref}">here</a>.`;
        }
      }
    }]);
    progressor.form = detailsForm;
    UPLOADING_QUEUE.enqueue(progressor);
    e.target.querySelector('.tabs').scrollIntoView();
    event.preventDefault();
  });
});
