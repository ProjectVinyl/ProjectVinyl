import { ready, bindEvent } from '../../jslim/events';
import { alignLists } from './row';

ready(() => {
  alignLists();
  return bindEvent(window, 'resize', alignLists);
});
