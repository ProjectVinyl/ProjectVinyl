import { ready, addDelegatedEvent } from '../../jslim/events';
import { canPlayType } from '../../utils/videos';
import { UploadQueue } from './queue';
import { ofAll, initProgressor } from './progress_bar_callback';

const UPLOADING_QUEUE = new UploadQueue();

function triggerFileReady(data, sender) {
  (sender || document).dispatchEvent(new CustomEvent('video_file_drop', {
    detail: { data: data }, bubbles: true, cancelable: true
  }));
  return data;
}

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab} = e.detail.data;

  const videoInput = el.querySelector('#video-upload input[type=file]');

  if (!videoInput) {
    return;
  }

  const detailsForm = el.querySelector('.details-form');

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
        if (data.upload_id) {
          fileParams.id = data.upload_id;
        }
        if (data.params) {
          fileParams.params = data.params;
        }

        if (!data.success) {
          detailsForm.dataset.uploadError = data.error.title + ': ' + data.error.description;
        }
        triggerFileReady(fileParams, el);
      },
      error(error) {
        detailsForm.dataset.uploadError = `Upload failed with "${error}". Please try again.`;
        triggerFileReady(fileParams, el);
      }
    }]);
    tabProgressBar.form = videoInput.form;
    detailsForm.dataset.uploadError = '';
    UPLOADING_QUEUE.enqueue(tabProgressBar);
    triggerFileReady(fileParams, el);
  });
});
