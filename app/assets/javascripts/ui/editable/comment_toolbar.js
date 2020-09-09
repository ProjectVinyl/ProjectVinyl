import { getAppKey } from '../../data/all';
import { addDelegatedEvent } from '../../jslim/events';
import { insertTags } from './bbcode';

/*comment_toolbar*/
const emoticons = getAppKey('emoticons_array');
const specialActions = {
  tag: (sender, textarea) => {
    const tag = sender.dataset.tag;
    insertTags(textarea, `[${tag}]`, sender.dataset.close ? '' : `[/${tag}]`);
  },
  emoticons: sender => {
    sender.classList.remove('edit-action');
    sender.querySelector('.pop-out').innerHTML = emoticons.map(e => `<li class="edit-action" data-action="emoticon" title=":${e}:">
      <span class="emote" data-emote="${e}" title=":${e}:"></span>
    </li>`).join('');
  },
  emoticon: (sender, textarea) => insertTags(textarea, sender.title, '')
};
addDelegatedEvent(document, 'mouseup', '.edit-action', (e, target) => {
  const type = specialActions[target.dataset.action];
  if (type) type(target, target.closest('.content').querySelector('textarea, input.comment-content'));
});
addDelegatedEvent(document, 'dragstart', '#emoticons .emote[title]', (event, target) => {
  let data = event.dataTransfer.getData('Text/plain');
  if (data && data.trim().indexOf('[') == 0) {
    data = data.split('\n').map(a => a.trim().replace(/\[/g, '').replace(/\]/g, '')).join('');
    event.dataTransfer.setData('Text/plain', data);
  } else {
    event.dataTransfer.setData('Text/plain', target.title);
  }
});
