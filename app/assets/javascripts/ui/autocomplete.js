import { ajax } from '../utils/ajax';
import { addDelegatedEvent } from '../jslim/events';

addDelegatedEvent(document, 'lookup:complete', '.auto-lookup', (e, target) => {
  target.querySelector('.pop-out').innerHTML = e.detail.results.map((a, i) => `<li data-index="${i}" data-slug="${a.slug}">
    <i class="fa fa-fw fa-user"></i> <span>${a.name.replace(e.detail.term, `<b>${e.detail.term}</b>`)}</span>
  </li>`).join('');
});

addDelegatedEvent(document, 'focusin', '.auto-lookup:not(.loaded) input', (e, input) => {
  let autocomplete = null;
  let lastValue = '';
  
  let results = [];
  
  const container = input.closest('.auto-lookup');
  container.classList.add('loaded');
  
  const popout = container.querySelector('.pop-out');
  
  input.addEventListener('focus', focus);
  input.addEventListener('blur', () => {
    container.classList.remove('focus');
    if (!autocomplete) return;
    clearInterval(autocomplete);
    autocomplete = null;
  });
  addDelegatedEvent(popout, 'click', 'li[data-index]', (e, target) => {
    const item = results[target.dataset.index];
    if (!item) return;
    input.value = item.name;
    popout.parentNode.dispatchEvent(new CustomEvent('lookup:insert', { detail: item, bubbling: true, cancellable: true }));
    container.classList.remove('pop-out-shown');
  });
  focus();
  
  function focus() {
    if (autocomplete) return;
    autocomplete = setInterval(() => {
      const value = input.value.trim();
      if (value.length && value !== lastValue) {
        lastValue = value;
        ajax.get(container.dataset.action, {
          q: value, validate: input.classList.contains('validate')
        }).json(json => {
          results = json.results;
          container.classList.toggle('pop-out-shown', results.length);
          input.classList.toggle('invalid', json.reject);
          popout.dispatchEvent(new CustomEvent('lookup:complete', {
            detail: json,
            bubbles: true,
            cancellable: true
          }));
        });
      }
    }, 1000);
    container.classList.add('focus');
    container.classList.toggle('pop-out-shown', results.length);
  }
});