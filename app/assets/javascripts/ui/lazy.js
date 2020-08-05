import { ajax } from '../utils/ajax';
import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', '.load-more button', (e, button) => {
  if (button.classList.contains('working')) return;
  
  const page = ++button.dataset.page;
  const target = document.getElementById(button.dataset.target);
  
  button.classList.add('working');
  ajax.get(button.dataset.url, {page: page}).json(json => {
    button.classList.remove('working');
    
    if (json.page == page) {
      target.insertAdjacentHTML('beforeend', json.content);
    } else {
      button.parentNode.removeChild(button);
    }
    button.dispatchEvent(new CustomEvent('resize', {bubbles: true}));
  });
});

addDelegatedEvent(document, 'mousedown', '.mix a', (e, target) => {
  target.href = `${target.dataset.href}&t=${document.querySelector('#video .player').getPlayerObj().video.currentTime}`;
});
