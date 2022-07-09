import { fullscreenPlayer } from './fullscreen';
import { onPlaylistNavigate } from './playlist';
import { cookies } from '../../utils/cookies';
import { addDelegatedEvent } from '../../jslim/events';
import { ajax } from '../../utils/ajax';

export function moveNext(player) {
  const item = selectNextItem();

  if (item) {
    if (!player.embedded && !fullscreenPlayer) {
      return item.click();
    }
    navTo(player, item);
  }
}

export function navTo(player, button) {
  ajax.get(`videos/${button.dataset.videoId}.json?list=${button.dataset.albumId}`).json(json => {
    onPlaylistNavigate(player, button, json);
  });
}

function selectNextItem() {
  let item;

  if (getShufflePlaylist()) {
    item = getRandomItem();
    if (!item && getLoopPlaylist()) {
      clearSeen();
      item = getRandomItem();
    }
  } else {
    item = document.querySelector('#playlist_next:not(.disabled)');
    if (!item && getLoopPlaylist()) {
      clearSeen();
      item = document.querySelectorAll('.playlist .row')[0];
    }
  }
  
  return item;
}

function getRandomItem() {
  const options = document.querySelectorAll('.playlist .row:not(.seen, .virtual)');
  const max = options.length;
  if (max <= 0) {
    return null;
  }
  return options[Math.floor(Math.random() * (max - 1))];
}

function clearSeen() {
  cookies.set('shuffle_past_videos', '{}', {session: true});
  document.querySelectorAll('.playlist .row.seen').forEach(a => a.classList.remove('seen'));
}
function getLoopPlaylist() {
  return cookies.get('loop') == '1';
}
function getShufflePlaylist() {
  return cookies.get('shuffle') == '1';
}

addDelegatedEvent(document, 'click', '.playlist .controls a[name]', (e, target) => {
  if (e.button) {
    return;
  }
  e.preventDefault();
  target.classList.toggle('active');
  cookies.set(target.name, target.classList.contains('active') ? '1' : '0');
  if (target.name == 'shuffle') {
    clearSeen();
  }
});
addDelegatedEvent(document, 'click', '#playlist_next', (e, target) => {
    if (e.button) {
    return;
  }
  if (getShufflePlaylist()) {
    
    const item = selectNextItem();
    if (item && item != target) {
      e.preventDefault();
      item.click();
    }
  }
});
