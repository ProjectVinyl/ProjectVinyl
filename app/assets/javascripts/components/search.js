import { ready, addDelegatedEvent } from '../jslim/events';

ready(() => {
  const searchTags = document.getElementById('search_tags');
  addDelegatedEvent(document, 'change', '#search_type', (e) => {
    const value = e.target.value;
    searchTags.classList.toggle('hidden', value != '0' && value != '2');
  });
  
  const searchInput = document.getElementById('search_small');
  addDelegatedEvent(document, 'change', '#search #search_type_small', (e) => {
    const value = e.target.value;
    if (value === '0' || value === '2') {
      searchInput.name = 'tagquery';
      searchInput.placeholder = 'Tag Search';
    } else {
      searchInput.name = 'query';
      searchInput.placeholder = 'Search';
    }
  });
});

// Hover events for labels in the search forms (and other places, maybe, eventually)
addDelegatedEvent(document, 'focusin', 'label input, label select', (e) => {
  e.target.closest('label').classList.add('focus');
});

addDelegatedEvent(document, 'focusout', 'label input, label select', (e) => {
  e.target.closest('label').classList.remove('focus');
});