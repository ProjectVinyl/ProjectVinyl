import { getAppKey } from '../data/all';
import { toggle } from './client';
import { ready } from '../jslim/events';

// The current signed-in user.
const current_user = getAppKey('current_user');

ready(() => {
  const key = 'give_me_notifications';
  const noticeMe = document.getElementById(key);

  if (noticeMe) {
    noticeMe.checked = localStorage[key] == '1';
    noticeMe.addEventListener('change', e => {
      localStorage[key] = e.target.checked ? '1' : '0';
      noticeMe.classList.add('disabled');
      toggle(e.target.checked, () => noticeMe.classList.remove('disabled'));
    });
  }

  toggle(current_user && !!localStorage[key]);
});
