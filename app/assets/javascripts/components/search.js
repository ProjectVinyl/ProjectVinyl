import { jSlim } from '../utils/jslim.js';

function setupSearch() {
  var searchInput = document.querySelector('#search input');
  var searchSelect = document.querySelector('#search select');
  
  var searchType = document.getElementById('search_type');
  var searchTags = document.getElementById('search_tags');
  
  if (searchSelect) {
    searchSelect.addEventListener('change', function() {
      var value = searchSelect.value;
      if (value === '0' || value === '2') {
        searchInput.name = 'tagquery';
        searchInput.placeholder = 'Tag Search';
      } else {
        searchInput.name = 'query';
        searchInput.placeholder = 'Search';
      }
    });
  }
  
  if (searchType) {
    searchType.addEventListener('change', function() {
      var value = searchType.value;
      if (value === '0' || value === '2') {
        searchTags.style.display = '';
      } else {
        searchTags.style.display = 'none';
      }
    });
  }
}

jSlim.ready(setupSearch);
