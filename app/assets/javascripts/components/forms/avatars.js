import { addDelegatedEvent } from '../../jslim/events';
import { all } from '../../jslim/dom';

addDelegatedEvent(document, 'ajax:complete', 'form.js-avatar-select', (e, target) => {
  const input = target.querySelector('.avatar.file-select input');
  const ext = input.files.length ? input.files[0].name.split('.').reverse()[0] : 'png';
  const img = `url(/avatar/${target.dataset.id}.${ext}?${new Date().getTime()})`;

  all(target, '.preview', el => el.style.backgroundImage = img);
  all('#login .avatar-wrapper.small span', el => el.style.backgroundImage = img);
});
