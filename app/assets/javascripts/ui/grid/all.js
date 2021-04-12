import { ready, bindEvent } from '../../jslim/events';
import { alignLists } from './row';
import { resizeGrid } from './split';

ready(() => {
  const columnRight = document.querySelector('.grid-root.column-right');
  if (!columnRight) {
    alignLists();
    return bindEvent(window, 'resize', alignLists);
  }
  
  const columnLeft = document.querySelector('.grid-root.column-left');
  
  function resize() {
    alignLists();
    resizeGrid(columnLeft, columnRight);
  }
  
  bindEvent(window, 'resize', resize);
  resize();
});
