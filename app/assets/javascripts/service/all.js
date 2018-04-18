import { initWorker } from './client';
import { deregisterWorker } from './service';
import { ready } from '../jslim/events';

ready(() => {
  const key = 'give_me_notifications';
  const noticeMe = document.getElementById(key);
  
  if (noticeMe) {
    noticeMe.checked = localStorage[key] == '1';
    
    function callback() {
  		noticeMe.classList.remove('disabled');
  	}
    
    noticeMe.addEventListener('change', e => {
      localStorage[key] = e.target.checked ? '1' : '0';
      
      noticeMe.classList.add('disabled');
      
      if (!e.target.checked) deregisterWorker(callback);
      if (e.target.checked) initWorker(callback);
    });
  }
  
  if (current_user && !!localStorage[key]) {
    initWorker();
  }
});
