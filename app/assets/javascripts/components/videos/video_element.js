/*
 * Initialises basic video playback functionality.
 */
import { bindAll } from '../../jslim/events';
import { sendMessage } from './itc';
import { setWatchTime } from './watch_time';
import { moveNext } from './playlist_actions';

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

  if (sender.params.time) {
    if (sender.isReady()) {
      video.currentTime = sender.params.time;
    } else {
      const setTime = () => {
        video.currentTime = sender.params.time;
        video.removeEventListener('canplay', setTime);
      };
      video.addEventListener('canplay', setTime);
    }
  }
  
  const sources = video.querySelectorAll('source');
  if (sources.length) {
    sources[sources.length - 1].addEventListener('error', e => sender.error(e, 'source'));
  }
  
  let suspendTimer = null;
  function suspended() {
    if (!suspendTimer) suspendTimer = setTimeout(() => {
      suspendTimer = null;
      sender.suspend.classList.remove('hidden');
    }, 300);
  }
  
  bindAll(video, {
    abort: e => sender.error(e, 'abort'),
    error: e => sender.error(e, 'video-error'),
    pause: () => sender.pause(),
    play: () => {
      sender.setState('playing');
      video.loop = !!sender.__loop;
      sendMessage(sender);
      sender.volume(video.volume, video.muted);
    },
    ended: () => {
      if (sender.__autoplay) {
        moveNext(sender);
      } else if (sender.pause()) {
        sender.setState('stopped');
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
      setWatchTime(sender.params.id, video.currentTime / sender.getDuration());
    },
    progress: () => {
      sender.controls.repaintProgress(video);
    }
  });
  
  return video;
}
