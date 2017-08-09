import { jSlim } from '../utils/jslim';

jSlim.ready(() => {
  const searchInput = document.querySelector('#search input');
  const searchSelect = document.querySelector('#search select');
  
  if (searchSelect) {
    searchSelect.addEventListener('change', () => {
      let value = searchSelect.value;
      if (value === '0' || value === '2') {
        searchInput.name = 'tagquery';
        searchInput.placeholder = 'Tag Search';
      } else {
        searchInput.name = 'query';
        searchInput.placeholder = 'Search';
      }
    });
  }
  
  const searchType = document.getElementById('search_type');
  const searchTags = document.getElementById('search_tags');
  
  if (searchType) {
    searchType.addEventListener('change', () => {
      let value = searchType.value;
      searchTags.style.display = (value === '0' || value === '2') ? '' : 'none';
    });
  }
});

// Hover events for labels in the search forms (and other places, maybe, eventually)
jSlim.on(document, 'focusin', 'label input, label select', function() {
  this.closest('label').classList.add('focus');
});

jSlim.on(document, 'focusout', 'label input, label select', function() {
  this.closest('label').classList.remove('focus');
});