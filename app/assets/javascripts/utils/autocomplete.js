import { ajax } from './ajax';
import { jSlim } from './jslim';

let autocomplete = null;

function lookup(sender, popout, action, input, validate) {
  ajax.post(action + '/lookup', {
    query: input.value, validate: validate ? 1 : 0
  }).json(function(json) {
    popout.innerHTML = '';
    for (let i = 0; i < json.content.length; i++) {
      let item = document.createElement('li');
      item.textContext = `${json.content[i][1]} (#${json.content[i][0]})`;
      item.dataset.name = json.content[i][1];
      item.addEventListener('mousedown', () => {
        input.value = item.dataset.name;
        sender.classList.remove('pop-out-shown');
      });
      popout.appendChild(item);
    }
    sender.classList[json.content.length ? 'add' : 'remove']('pop-out-shown');
    sender.classList[json.reject ? 'add' : 'remove']('invalid');
  });
}

jSlim.on(document, 'focusin', '.auto-lookup:not(.loaded) input', function() {
  const input = this;
  const me = input.parentNode;
  const popout = me.querySelector('.pop-out');
  const action = me.dataset.action;
  const validate = me.classList.contains('validate');
  let lastValue = null;
  
  me.classList.add('loaded');

  input.addEventListener('blur', () => {
    clearInterval(autocomplete);
    autocomplete = null;
  });

  input.addEventListener('focus', () => {
    if (!autocomplete) {
      autocomplete = setInterval(() => {
        let value = input.value;
        if (value != lastValue) {
          lastValue = value;
          lookup(me, popout, action, input, validate);
        }
      }, 1000);
    }
  });
});
