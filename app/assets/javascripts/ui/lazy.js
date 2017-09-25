import { ajax } from '../utils/ajax';
import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'click', '.load-more button', (e, button) => {
  const page = parseInt(button.dataset.page) + 1;
  
  button.classList.add('working');
  ajax.get(button.dataset.url, {
    page: page
  }).json(json => {
    const target = document.getElementById(button.dataset.target);
    
    button.classList.remove('working');
    if (json.page == page) {
      target.innerHTML += json.content;
      button.dataset.page = page;
    } else {
      button.parentNode.removeChild(button);
    }
  });
});

addDelegatedEvent(document, 'click', '.mix a', (e, target) => {
  document.location.replace(`${target.href}&t=${document.querySelector('#video .player').getPlayerObj().video.currentTime}`);
  e.preventDefault();
});
