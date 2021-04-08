import { addDelegatedEvent } from '../../jslim/events';
import { insert } from '../../ui/reorder';

addDelegatedEvent(document, 'ajax:complete', 'form.js-module-creator', (e, target) => {
  insert(e.detail.data.target, e.detail.data.index, e.detail.data.html);
});
