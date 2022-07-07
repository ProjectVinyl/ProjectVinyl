import { all, nodeFromHTML } from '../../jslim/dom';
import { ready, addDelegatedEvent, dispatchEvent } from '../../jslim/events';
import { fillTemplate } from '../../utils/template';
import { focusTab } from '../../ui/tabsets/tabset';

function setupUploaderFrame(frame) {
  const instances = [];
  const tabTemplate = document.querySelector(frame.dataset.tabTemplate).innerHTML;
  const contentTemplate = document.querySelector(frame.dataset.contentTemplate).innerHTML;

  function detectExisting() {
    const tabs = frame.querySelectorAll('.uploader-frame-tab-bar .button[data-target]');
    tabs.forEach(tab => {
      const el = frame.querySelector(`.tab[data-tab="${tab.dataset.target}"]`);
      if (!el) {
        tab.remove();
      } else {
        const id = instances.length;
        const instance = { tab, el, id, initial: true };
        instances.push(instance);
        addDelegatedEvent(tab, 'click', 'i.fa-close', e => destroyInstance(instance));
        requestAnimationFrame(() => dispatchEvent('frame:tab_created', instance, frame));
      }
    });
  }

  function destroyInstance(instance) {
    instances.splice(instances.indexOf(instance), 1);
    dispatchEvent('frame:tab_destroyed', instance, frame);

    if (!instances.length) {
      setTimeout(createInstance, 100);
    }
  }

  function createInstance() {
    pushInstance(contentTemplate, tabTemplate);
  }

  function pushInstance(contentTemplate, tabTemplate) {
    const id = instances.length;
    const el = nodeFromHTML(fillTemplate({ id, index: id + 1 }, contentTemplate));
    const tab = nodeFromHTML(fillTemplate({ id, index: id + 1 }, tabTemplate));

    const instance = {id, el, tab };

    frame.appendChild(el);
    frame.querySelector('#new_tab_button').insertAdjacentElement('beforebegin', tab);

    // FIXME
    requestAnimationFrame(() => tab.classList.remove('hidden'));

    addDelegatedEvent(tab, 'click', 'i.fa-close', e => destroyInstance(instance));

    focusTab(tab);
    instances.push(instance);
    dispatchEvent('frame:tab_created', instance, frame);
  }

  addDelegatedEvent(frame, 'click', '#new_tab_button', e => {
    if (e.button === 0) {
      createInstance();
    }
  });
  frame.addEventListener('frame:frame_content', e => {
    pushInstance(e.detail.data.editor, e.detail.data.tab);
  });

  detectExisting(instances, frame);
  if (!instances.length) {
    createInstance();
  }
}

ready(() => all('#uploader_frame', setupUploaderFrame));