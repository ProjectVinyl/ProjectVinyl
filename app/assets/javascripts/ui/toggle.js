import { ajax } from '../utils/ajax';
import { jSlim } from '../utils/jslim';

function toggle(sender) {
  var data = {};
  
  if (sender.dataset.item) {
    data.item = sender.dataset.item;
  }
  if (sender.dataset.with) {
    data.extra = document.querySelector(sender.dataset.with).value;
  }
  
  ajax.put(sender.dataset.target + '/' + sender.dataset.id + '/' + sender.dataset.action, data).json(function(json) {
    if (sender.dataset.family) {
      return jSlim.all('.action.toggle[data-family="' + sender.dataset.family + '"][data-id="' + sender.dataset.id + '"]', function(t) {
        updateCheck(t, json[t.dataset.descriminator]);
      });
    }
    
    updateCheck(sender, json.added);
    if (sender.dataset.state) {
      sender.closest(sender.dataset.parent).classList.toggle(sender.dataset.state, json.added);
    }
  });
}

function updateCheck(element, state) {
  var check = element.dataset.checkedIcon || 'check';
  var uncheck = element.dataset.uncheckedIcon;
  element.querySelector('.icon').innerHTML = state ? '<i class="fa fa-' + check + '"></i>' : uncheck ? '<i class="fa fa-' + uncheck + '"></i>' : '';
}

function toggleState(sender) {
  var state = sender.dataset.state;
  var parent = sender.dataset.parent;
  
  parent = parent ? sender.closest(parent) : sender.parentNode;
  parent.classList.toggle(state);
  
  sender.innerText = sender.dataset[parent.classList.contains(state)];
  sender.dispatchEvent(new CustomEvent('toggle', { bubbles: true }));
}

jSlim.on(document, 'click', '.action.toggle', function(e) {
  if (e.which != 1 && e.button != 0) return;
  toggle(this);
  e.preventDefault();
});

jSlim.on(document, 'click', '.state-toggle', function(e) {
  if (e.which != 1 && e.button != 0) return;
  toggleState(this);
  e.preventDefault();
});
