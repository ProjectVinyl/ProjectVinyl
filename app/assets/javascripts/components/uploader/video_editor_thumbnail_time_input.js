import { addDelegatedEvent } from '../../jslim/events';
import { ThumbPicker } from './thumbnail_picker';
import { validateVideoForm } from './video_form_validations';
import { canPlayType } from '../../utils/videos';

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab,id,initial} = e.detail.data;
  const detailsForm = el.querySelector('.details-form');

  let lastTime = -1;
  const thumbnailTime = el.querySelector('#time');
  const thumbPicker = el.querySelector(`.tab[data-tab="thumbpick_${id}"]`);
  thumbPicker.addEventListener('tabblur', () => {
    lastTime = thumbnailTime.value;
    thumbnailTime.value = -1;
  });
  thumbPicker.addEventListener('tabfocus', () => {
    thumbnailTime.value = lastTime;
  });

  const player = new ThumbPicker();
  player.constructor(el.querySelector('.video'));

  const picker = el.querySelector(`li[data-target="thumbpick_${id}"]`);
  const uploader = el.querySelector(`li[data-target="thumbupload_${id}"]`);

  const validationCallback = () => validateVideoForm(detailsForm);

  picker.addEventListener('tabblur', validationCallback);
  picker.addEventListener('tabfocus', validationCallback);

  const coverInput = el.querySelector('#cover-upload input[type=file]');
  coverInput.addEventListener('change', () => {
    detailsForm.dataset.hasCover = true;
  });
  el.addEventListener('video_file_drop', event => {
    const {needsCover, mime, file, id, params} = event.detail.data;

    detailsForm.dataset.needsCover = needsCover;

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
  
  if (initial) {
    player.play();
    player.skipTo(thumbnailTime.value);
    validationCallback();
  }
});
