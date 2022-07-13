import { errorMessage, errorPresent } from '../../utils/videos';
import { setupNoise } from './noise';

export function onVideoError(sender, e, source) {
  console.warn('Video playback failed due to error from ' + source);
  requestAnimationFrame(() => {
    if (errorPresent(sender.video)) {
      const message = errorMessage(sender.video);
      console.warn(message);

      sender.setState('error');
      sender.player.error.message.innerText = message;
      sender.suspend.classList.add('hidden');

      if (!sender.noise) {
        sender.noise = setupNoise(sender.player.error);
      }
    }
  });
}
