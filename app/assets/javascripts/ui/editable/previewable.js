import { ajaxGet } from '../../utils/ajax';
import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'toggle', '.previewable', (e, target) => {
  if (!e.detail.active) return; // only update when previewing enable (state off)
  if (target.classList.contains('loading')) return;
  target.classList.add('loading');
  
  ajaxGet('/api/html', { content: target.querySelector('textarea, input').value}).json(json => {
    const preview = target.parentNode.querySelector('.preview');
    preview.innerHTML = json.html;
    target.classList.remove('loading');
  });
});
