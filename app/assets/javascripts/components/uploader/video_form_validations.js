import { ready, addDelegatedEvent } from '../../jslim/events';
import { all } from '../../jslim/dom';
import { UploadQueue } from './queue';
import { initProgressor } from './progress_bar_callback';
import { getTagEditor } from '../tag_editor/all';
import { toBool } from '../../utils/misc';

function cleanup(title) {
  // 1. Convert everything to lowercase
  // 2. Remove any beginning digit strings
  // 3. Replace non-alpha/non-whitespace with a single space
  // 4. Convert first letters to uppercase
  // 5. Strip whitespace
  return (title || '')
    .toLowerCase()
    .replace(/[-_]|[^0-9a-z\s]/gi, ' ')
    .replace(/(^|\s)[a-z]/g, i => i.toUpperCase())
    .trim() || "Untitled";
}

function formatIssueList(issues) {
  return issues.map(i => `<div>* ${i}</div>`).join('<br>');
}

export function validateVideoForm(form) {
  const issues = getAllIssues(form);

  const submitButton = form.querySelector('button[name="publish"]');
  submitButton.disabled = !!issues.critical.length;

  const notify = form.querySelector('.notify');
  const bobber = notify.querySelector('.notify .bobber');
  const info = form.querySelector('.info');

  notify.classList.toggle('shown', !!issues.critical.length);
  bobber.innerHTML = formatIssueList(issues.critical);

  info.classList.toggle('hidden', !issues.minor.length);
  info.innerHTML = formatIssueList(issues.minor);
}

function getAllIssues(form) {
  const issues = {
    critical: [],
    minor: []
  };

  if (form.dataset.uploadError) {
    issues.critical.push(form.dataset.uploadError);
  } else if (!form.dataset.videoId) {
    issues.critical.push('Video is still processing. Please wait.');
  }

  if (form['premier[premier]'][1].checked) {
    const premierDate = form['premier[date]'].value;
    const premierTime = form['premier[time]'].value;

    if (!premierDate) {
      issues.critical.push('Premier date is not set');
    }
    if (!premierTime) {
      issues.critical.push('Premier time is not set');
    }

    if (new Date(premierDate + ' ' + premierTime) <= new Date()) {
      issues.critical.push('A premier must be set in the future');
    }
  }

  if (!form["video[title]"].value) {
    issues.critical.push('You need to provide a title.');
  }

  if (toBool(form.dataset.needsCover) && toBool(form.dataset.hasCover)) {
    issues.critical.push('Audio files require a cover photo.');
  }
  
  const tags = [];
  
  all(form, '.tag-editor', editor => {
    getTagEditor(editor).tags.baked().forEach(tag => {
      if (tags.indexOf(tag) === -1) {
        tags.push(tag);
      }
    });
  });

  if (!tags.length) {
    issues.critical.push('You need at least one tag.');
  }

  if (!form["video[source]"].value) {
    const hasSrcNeededTag = tags.indexOf('source needed') !== -1;

    if (!hasSrcNeededTag) {
      issues.minor.push('You have not provided a source. If you know what it is add it to the source field, otherwise consider tagging this video as \'source needed\' so others know to search for one.');
    }
  }

  return issues;
}

addDelegatedEvent(document, 'frame:tab_created', '#uploader_frame', e => {
  const {el} = e.detail.data;

  const detailsForm = el.querySelector('.details-form');
  const validationCallback = () => validateVideoForm(detailsForm);

  detailsForm.addEventListener('tagschange', validationCallback);
  detailsForm.addEventListener('change', validationCallback);

  el.addEventListener('video_file_drop', event => {
    const file = event.detail.data;

    if (file.id) {
      detailsForm.dataset.videoId = file.id;
    }

    const title = cleanup(file.title);
    el.querySelector('#video_title .content').innerText = title;
    el.querySelector('#video_title input').value = title;

    validationCallback();
  });
});
