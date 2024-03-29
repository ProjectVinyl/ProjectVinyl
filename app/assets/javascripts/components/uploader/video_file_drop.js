import { ready, addDelegatedEvent, dispatchEvent } from '../../jslim/events';
import { canPlayType } from '../../utils/videos';
import { UploadQueue } from './queue';
import { ofAll, initProgressor } from './progress_bar_callback';

const UPLOADING_QUEUE = new UploadQueue();

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab} = e.detail.data;

  const videoInput = el.querySelector('#video-upload input[type=file]');

  if (!videoInput) {
    return;
  }

  const detailsForm = el.querySelector('.details-form');
  const thumbnailForm = el.querySelector('.thumbnail-form');

  addDelegatedEvent(el, 'click', 'button[name="change_video"]', () => {
    videoInput.click();
  });

  videoInput.addEventListener('change', () => {
    const file = videoInput.files[0];
    const mime = file.type;
    const fileParams = {
      mime, file,
      title: file.name.split('.')[0],
      needsCover: !!file.type.match(/audio\//),
      name: file.name
    };

    if (!canPlayType(mime)) {
      alert("File format is not supported");
      return;
    }

    const tabProgressBar = ofAll([initProgressor(tab), {
      complete(data) {
        if (data.media_update_url) {
          videoInput.form.action = data.media_update_url;
          videoInput.form._method.value = 'patch';
        }
        if (data.details_update_url) {
          detailsForm.action = data.details_update_url;
        }
        if (data.thumbnail_update_url) {
          thumbnailForm.action = data.thumbnail_update_url;
        }
        if (data.upload_id) {
          fileParams.id = data.upload_id;
        }
        if (data.params) {
          fileParams.params = data.params;
        }

        if (!data.success) {
          detailsForm.dataset.uploadError = data.error.title + ': ' + data.error.description;
        }
        dispatchEvent('video_file_drop', fileParams, el);
      },
      error(error) {
        detailsForm.dataset.uploadError = `Upload failed with "${error}". Please try again.`;
        dispatchEvent('video_file_drop', fileParams, el);
      }
    }]);
    tabProgressBar.form = videoInput.form;
    detailsForm.dataset.uploadError = '';
    UPLOADING_QUEUE.enqueue(tabProgressBar);
    dispatchEvent('video_file_drop', fileParams, el);
  });
});
