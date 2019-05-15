/*
 * Initialises basic video playback functionality.
 */
import { bindAll } from '../../jslim/events';
import { fullscreenPlayer } from './fullscreen';
import { sendMessage } from './itc';


// Have to do this the long way to avoid caching errors in firefox
export function addSource(video, src, type) {
  const source = document.createElement('SOURCE');
  source.type = type;
  source.src = src;
  video.appendChild(source);
}

export function createVideoElement(sender) {
  const video = sender.createMediaElement();
  sender.player.media.appendChild(video);
  
  if (sender.time) {
    if (sender.isReady()) {
      video.currentTime = sender.time;
    } else {
      const setTime = () => {
        video.currentTime = sender.time;
        video.removeEventListener('canplay', setTime);
      };
      video.addEventListener('canplay', setTime);
    }
  }
  
  const sources = video.querySelectorAll('source');
  if (sources.length) {
    sources[sources.length - 1].addEventListener('error', e => sender.error(e));
  }
  
  let suspendTimer = null;
  function suspended() {
    if (!suspendTimer) suspendTimer = setTimeout(() => {
      suspendTimer = null;
      sender.suspend.classList.remove('hidden');
    }, 300);
  }
  
  bindAll(video, {
    abort: e => sender.error(e), error: e => sender.error(e),
    pause: () => sender.pause(),
    play: () => {
      sender.player.dataset.state = 'playing';
      video.loop = !!sender.__loop;
      sendMessage(sender);
      sender.volume(video.volume, video.muted);
    },
    ended: () => {
      if (sender.__autoplay) {
        const next = document.querySelector('#playlist_next');
        if (next) {
          if (!sender.embedded && !fullscreenPlayer) return sender.click();
          sender.navTo(next);
        }
      } else if (sender.pause()) {
        sender.player.dataset.state = 'stopped';
      }
    },
    suspend: suspended,
    waiting: suspended,
    stalled: suspended,
    volumechange: () => {
      sender.volume(video.volume, video.muted || video.volume === 0);
    },
    seek: () => {
      sender.track(video.currentTime, sender.getDuration());
    },
    timeupdate: () => {
      if (suspendTimer) {
        clearTimeout(suspendTimer);
        suspendTimer = null;
      }
      sender.track(video.currentTime, sender.getDuration());
    },
    progress: () => {
      sender.controls.repaintProgress(video);
    }
  });
  
  return video;
}
