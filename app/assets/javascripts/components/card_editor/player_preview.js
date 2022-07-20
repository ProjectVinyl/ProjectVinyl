import { TimeSelecter } from '../uploader/time_selecter';
import { addDelegatedEvent, bindEvent } from '../../jslim/events';

bindEvent(document, 'ajax:externalform', (ev, target) => {
  const editor = target.querySelector('.js-video-card-editor');
  if (editor) {
    editor.player = new TimeSelecter(editor.querySelector('.video'));
    editor.player.play();
  }
});
