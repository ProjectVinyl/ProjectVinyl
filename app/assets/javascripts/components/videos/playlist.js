/*
 * Initialises basic video playback functionality.
 */
import { ajax } from '../../utils/ajax';
import { scrollTo } from '../../ui/scroll';

export function onPlaylistNavigate(player, sender, json) {
  let selected = document.querySelector('.playlist a.selected');

  if (selected) {
    selected.classList.remove('selected');
  }
  selected = document.querySelector(`.playlist a[data-id="${json.id}"]`);
  selected.classList.add('selected');

  scrollTo(selected, document.querySelector('.playlist .scroll-container'));
  
  const next = document.querySelector('#playlist_next');
  const prev = document.querySelector('#playlist_prev');
  
  if (next && json.next) {
    next.href = json.next.link;
    next.dataset.videoId = json.next.id;
  }

  if (prev && json.prev) {
    prev.href = json.prev.link;
    prev.dataset.videoId = json.prev.id;
  }
  
  player.redirect = sender.href;
  player.loadAttributesAndRestart(json.current);
  
  if (!player.embedded) {
    if (next && !json.next) {
      next.parentNode.removeChild(next);
      document.querySelector('.buff-right').classList.remove('buff-right');
    }
    if (prev && !json.prev) {
      prev.parentNode.removeChild(prev);
    }
  }
}
