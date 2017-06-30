import { ajax } from './ajax.js';
import { jSlim } from './jslim.js';

function count(me, offset, save) {
  var likes = me.dataset.count;
  var count = me.querySelector('.count');
  
  if (!count) {
    count = me.querySelector('span');
    count.innerHTML = '<span class="count"></span>';
    count = count.firstChild;
  }
  
  likes = likes ? parseInt(likes) : 0;
  likes += offset;
  me.dataset.count = likes;
  me.classList.toggle('liked', offset > 0);
  count.innerText = likes;
  count.classList.toggle('hidden', likes < 1);
  
  if (save) {
    ajax.post(me.dataset.action + '/' + me.dataset.id + '/' + offset, function(json) {
      if (count.length) count.innerText = json.count;
    });
  }
}

jSlim.on(document, 'click', 'button.action.like, button.action.dislike', function(e) {
  if (e.which != 1 && e.button != 0) return;
  if (this.classList.contains('liked')) {
    count(this, -1, true);
  } else {
    var other = this.parentNode.querySelector('.liked');
    if (other) {
      count(other, -1, false);
    }
    count(this, 1, true);
  }
});

jSlim.on(document, 'click', 'button.action.star', function fave(e) {
  if (e.which != 1 && e.button != 0) return;
  this.classList.toggle('starred');
  var self = this;
  ajax.post(this.dataset.action + '/' + this.dataset.id, function(xml) {
    self.classList.toggle('starred', xml.added);
  });
});
