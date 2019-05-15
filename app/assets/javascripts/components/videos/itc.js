/*
 * Inter-Tab Communications
 */
import { bindEvent } from '../../jslim/events';

export function sendMessage(sender) {
  if (!sender.__sendMessages) {
    return;
  }
  
  let id = parseInt(localStorage['::activeplayer'] || '0');
  sender.__seed = ((id + 1) % 3).toString();
  localStorage.setItem('::activeplayer', sender.__seed);
}

export function attachMessageListener(sender, subscribe) {
  sender.__sendMessages = subscribe;

  if (subscribe) {
    bindEvent(window, 'storage', event => {
      if (event.key === '::activeplayer' && event.newValue !== sender.__seed) {
        sender.pause();
      }
    });
  }
}
