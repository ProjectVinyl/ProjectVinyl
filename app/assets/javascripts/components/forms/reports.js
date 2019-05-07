import { uploadForm } from '../../utils/progressform';
import { addDelegatedEvent } from '../../jslim/events';

addDelegatedEvent(document, 'submit', '.form.report form', (e, sender) => {
  uploadForm(sender, {
    success: (data, message) => {
      message.innerHTML = '<i style="color: lightgreen; font-size: 50px;" class="fa fa-check"></i></br>Thank you! Your report will be addressed shortly.';
    },
    error: (error, message) => {
      message.innerHTML = `<i style="color: red; font-size: 50px;" class="fa fa-times"></i><br>Error: ${error}<br>Please contact <a href="mailto://support@projectvinyl.net">support@projectvinyl.net</a> for assistance.`;
    }
  }, e);
});
