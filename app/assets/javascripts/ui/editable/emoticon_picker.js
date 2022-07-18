import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'dragstart', '#emoticons .emote[title]', (event, target) => {
  let data = event.dataTransfer.getData('Text/plain');
  if (data && data.trim().indexOf('[') == 0) {
    data = data.split('\n').map(a => a.trim().replace(/\[/g, '').replace(/\]/g, '')).join('');
    event.dataTransfer.setData('Text/plain', data);
  } else {
    event.dataTransfer.setData('Text/plain', target.title);
  }
});
