import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';

let autocomplete = null;

jSlim.on(document, 'focusin', '.auto-lookup:not(.loaded) input', (e, input) => {
  const me = input.parentNode;
  const popout = me.querySelector('.pop-out');
  const action = me.dataset.action;
  const validate = me.classList.contains('validate');
  let lastValue = null;
  
  me.classList.add('loaded');
  
	jSlim.on(popup, 'mousedown', '.auto-lookup li[data-name]', (e, sender) => {
		input.value = sender.dataset.name;
		me.classList.remove('pop-out-shown');
	});
	
  input.addEventListener('blur', () => {
    if (autocomplete) clearInterval(autocomplete);
    autocomplete = null;
  });
  
  input.addEventListener('focus', () => {
    if (!autocomplete) autocomplete = setInterval(() => {
			if (input.value == lastValue) return;
			lastValue = input.value;
			ajax.post(`${action}/lookup`, {
				query: input.value, validate: validate ? 1 : 0
			}).json(json => {
				popout.innerHTML = json.content.map(a => `<li data-name="${a[1]}">${a[1]} (${a[0]})</li>`).join('');
				me.classList.toggle('pop-out-shown', json.content.length);
				me.classList.toggle('invalid', json.reject);
			});
		}, 1000);
  });
});
