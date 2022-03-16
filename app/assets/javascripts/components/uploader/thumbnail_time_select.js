import { addDelegatedEvent } from '../../jslim/events';
import { TimeSelecter } from './time_selecter';
import { validateVideoForm } from './video_form_validations';
import { UploadQueue } from './queue';
import { canPlayType } from '../../utils/videos';
import { ofAll, initProgressor } from './progress_bar_callback';

const UPLOADING_QUEUE = new UploadQueue();

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab,id,initial} = e.detail.data;
  const detailsForm = el.querySelector('.details-form');
  const thumbnailForm = el.querySelector('.thumbnail-form');

  const player = new TimeSelecter();
  player.constructor(el.querySelector('.video'));

  const validationCallback = () => validateVideoForm(detailsForm);
  const picker = el.querySelector(`li[data-target="thumbpick_${id}"]`);
  const uploader = el.querySelector(`li[data-target="thumbupload_${id}"]`);

  let lastTime = -1;
  uploader.addEventListener('tabblur', () => {
    player.timeInput.value = lastTime;
    validationCallback();
  });
  uploader.addEventListener('tabfocus', () => {
    lastTime = player.timeInput.value;
    player.timeInput.value = -1;
    validationCallback();
  });

  el.addEventListener('video_file_drop', event => {
    const {needsCover, mime, file, id, params} = event.detail.data;

    if (params) {
      player.params = params;
    }

    if (needsCover) {
      player.load(null);
      uploader.click();
      picker.dataset.disabled = 1;
    } else {
      if (canPlayType(mime)) {
        player.load(file, true);
        picker.removeAttribute('data-disabled');
        picker.click();
      } else {
        uploader.click();
        picker.dataset.disabled = 1;
      }
    }
  });
  
  let prev = -2;
  if (initial) {
    player.play();
    player.skipTo(player.timeInput.value);
    validationCallback();
  }

  player.timeInput.addEventListener('change', () => {
    const time = parseFloat(player.timeInput.value);
    
    if (time != prev) {
      thumbnailForm.save.disabled = prev == -2 || time < 0;
      prev = time;
    }
  });
});
