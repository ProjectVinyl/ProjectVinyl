import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el,tab} = e.detail.data;

  const videoForm = el.querySelector('.video-file-form');

  el.addEventListener('video_file_drop', event => {
    const file = event.detail.data;

    if (videoForm && videoForm.classList.contains('shown')) {
      el.querySelectorAll('.ui.hidden, .ui.shown').forEach(e => {
        e.classList.toggle('hidden');
        e.classList.remove('shown');
      });
    }

    tab.querySelector('.label').innerText = file.name;
  });
});
