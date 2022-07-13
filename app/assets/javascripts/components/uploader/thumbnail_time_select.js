import { addDelegatedEvent } from '../../jslim/events';
import { TimeSelecter } from './time_selecter';
import { validateVideoForm } from './video_form_validations';
import { UploadQueue } from './queue';
import { canPlayType } from '../../utils/videos';

const UPLOADING_QUEUE = new UploadQueue();

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,id,initial} = e.detail.data;

  const player = new TimeSelecter(el.querySelector('.thumbnail-form.thumbnail-time-form .video'));
  const validationCallback = () => validateVideoForm(el.querySelector('.details-form'));
  const pickerTab = el.querySelector(`li[data-target="thumbpick_${id}"]`);
  const uploaderTab = el.querySelector(`li[data-target="thumbupload_${id}"]`);

  el.addEventListener('video_file_drop', event => {
    const {needsCover, mime, file, params} = event.detail.data;

    if (params) {
      player.params = params;
    }

    if (needsCover) {
      player.load(null);
      uploaderTab.click();
      pickerTab.dataset.disabled = 1;
    } else {
      if (canPlayType(mime)) {
        player.load(file, true);
        pickerTab.removeAttribute('data-disabled');
        pickerTab.click();
      } else {
        uploaderTab.click();
        pickerTab.dataset.disabled = 1;
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
      player.timeInput.form.save.disabled = prev == -2 || time < 0;
      prev = time;
    }
  });
});
