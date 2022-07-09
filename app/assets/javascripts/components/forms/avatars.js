import { addDelegatedEvent } from '../../jslim/events';

function getAvatarPreviewUrl(target) {
  const input = target.querySelector('.avatar.file-select input');

  if (!input.files.length) {
    return '/images/default-avatar.png';
  }

  const ext = input.files.length ? input.files[0].name.split('.').reverse()[0] : 'png';

  return `/avatar/${target.dataset.id}.${ext}?${new Date().getTime()}`;
}

addDelegatedEvent(document, 'ajax:complete', 'form.js-avatar-select', (e, target) => {
  const src = `url(${getAvatarPreviewUrl(target)})`;

  target.querySelector('.preview').style.backgroundImage = src;

  document.querySelectorAll('#login .avatar-wrapper.small span').forEach(el => el.style.backgroundImage = src);
});
