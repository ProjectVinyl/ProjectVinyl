import { popupConfirm } from '../components/popup';

document.addEventListener('click', function(event) {
  if (event.button !== 0 || event.handled) return;
  
  const target = event.target.closest('a[data-confirm], button[data-confirm], input[data-confirm]');
  if (!target) return;
  
  const message = target.dataset.confirm || 'Are you sure you want to continue?';
  const title = target.dataset.title || 'Confirm';
  
  // Stop this event
  event.stopPropagation();
  event.stopImmediatePropagation();
  event.preventDefault();
  
  const newEvent = new MouseEvent('click', event);
  newEvent.handled = true;
  
  popupConfirm(message, title).setOnAccept(function() {
    target.dispatchEvent(newEvent);
  });
});
