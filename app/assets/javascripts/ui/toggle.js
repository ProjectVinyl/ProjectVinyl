import { ajax } from '../utils/ajax.js';
import { jSlim } from '../utils/jslim.js';

function toggle(sender) {
  var id = sender.dataset.id;
  var action = sender.dataset.target + '/' + sender.dataset.action;
  var data = sender.dataset.with;
  var checkIcon = sender.dataset.checkedIcon || 'check';
  var uncheckIcon = sender.dataset.uncheckedIcon;
  var state = sender.dataset.state;

  if (data) action += `?extra=${document.querySelector(data).value}`;

  ajax.post(action, {
    id: id, item: sender.dataset.item
  }).json(function(json) {
    const family = sender.dataset.family;
    if (family) {
      return jSlim.all(`.action.toggle[data-family="${family}"][data-id="${id}"]`, t => {
        const uncheck = t.dataset.uncheckedIcon;
        const check = t.dataset.checkedIcon || 'check';
        t.querySelector('.icon').innerHTML = json[t.dataset.descriminator] ? `<i class="fa fa-${check}"></i>` : uncheck ? `<i class="fa fa-${uncheck}"></i>` : '';
      });
    }

    sender.querySelector('.icon').innerHTML = json.added ? `<i class="fa fa-${checkIcon}"></i>` : uncheckIcon ? `<i class="fa fa-${uncheckIcon}"></i>` : '';
    if (state) {
      sender.closest(sender.dataset.parent).classList[json.added ? 'add' : 'remove'](state);
    }
  });
}

jSlim.on(document, 'click', '.action.toggle', function() {
  toggle(this);
});

jSlim.on(document, 'click', '.state-toggle', function(ev) {
  var state = this.dataset.state;
  var parent = this.dataset.parent;

  parent = parent ? this.closest(parent) : this.parentNode;
  parent.classList.toggle(state);

  this.textContext = this.dataset[parent.classList.contains(state)];
  this.dispatchEvent(new CustomEvent('toggle', { bubbles: true }));

  ev.preventDefault();
});
