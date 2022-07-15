import { QueryParameters } from '../utils/queryparameters';
import { ready } from '../jslim/events';

ready(() => {
  const intention = QueryParameters.current.getItem('intention');
  
  
  if (intention) {
    const element = document.querySelector(`[data-external-form][data-intention-target=${intention}]`);
    
    if (element) {
      element.click();
    }
  }
});