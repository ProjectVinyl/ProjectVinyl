import { jSlim } from '../utils/jslim';

jSlim.ready(() => {
  function sizeSpannedBlocks() {
    jSlim.all('.row.row-spanned > .content', el => {
      el.parentNode.style.height = `${el.children[0].clientHeight}px`; // clientHeight not quite accurate
    });
  }

  if (document.querySelector('.row.row-spanned')) {
    jSlim.all('.state-toggle', el => el.addEventListener('toggle', sizeSpannedBlocks));
    jSlim.all('.row.row-spanned input, .row.row-spanned textarea', el => el.addEventListener('keyup', sizeSpannedBlocks));
    jSlim.all('.row.row-spanned .tag-editor', el => el.addEventListener('tagschange', sizeSpannedBlocks));
    window.addEventListener('resize', sizeSpannedBlocks);
  }
});
