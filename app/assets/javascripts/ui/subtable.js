import { ready, bindEvent } from '../jslim/events';
import { all } from '../jslim/dom';

function sizeSpannedBlocks() {
  all('.row.row-spanned > .content', el => el.parentNode.style.height = `${el.children[0].offsetHeight}px`);
}

ready(() => {
  if (!document.querySelector('.row.row-spanned')) return;
  
  all('.state-toggle', el => el.addEventListener('toggle', sizeSpannedBlocks));
  all('.row.row-spanned input, .row.row-spanned textarea', el => el.addEventListener('keyup', sizeSpannedBlocks));
  all('.row.row-spanned .tag-editor', el => el.addEventListener('tagschange', sizeSpannedBlocks));
  bindEvent(window, 'resize', sizeSpannedBlocks);
});
