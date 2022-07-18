import { getAppKey } from '../../data/all';
import { addDelegatedEvent } from '../../jslim/events';
import { insertTags } from './bbcode';

const emoticons = getAppKey('emoticons_array');
const specialActions = {
  tag: (sender, textarea) => {
    const tag = sender.dataset.tag;
    insertTags(textarea, `[${tag}]`, sender.dataset.close ? '' : `[/${tag}]`);
  },
  emoticons: sender => {
    sender.classList.remove('edit-action');
    sender.querySelector('.pop-out').innerHTML = emoticons.map(e => `<li class="edit-action" data-action="emoticon" title=":${e}:">
      <a class="emote" data-emote="${e}" title=":${e}:"></a>
    </li>`).join('');
  },
  emoticon: (sender, textarea) => insertTags(textarea, sender.title, '')
};

addDelegatedEvent(document, 'mouseup', '.edit-action', (e, target) => {
  if (e.button !== 0) return;
  const type = specialActions[target.dataset.action];
  if (type) type(target, target.closest('.content').querySelector('textarea, input.comment-content'));
});
