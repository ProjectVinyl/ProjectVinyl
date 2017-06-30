function setupSearch() {
  const searchInput = document.querySelector('#search input'),
        searchSelect = document.querySelector('#search select'),
        searchType = document.querySelector('#search_type'),
        searchTags = document.querySelector('#search_tags');

  searchSelect.addEventListener('change', () => {
    const value = searchSelect.value;
    if (value === '0' || value === '2') {
      searchInput.setAttribute('name', 'tagquery');
      searchInput.setAttribute('placeholder', 'Tag Search');
    } else {
      searchInput.setAttribute('name', 'query');
      searchInput.setAttribute('placeholder', 'Search');
    }
  });

  searchType && searchType.addEventListener('change', () => {
    const value = searchType.value;
    if (value === '0' || value === '2') {
      searchTags.style.display = '';
    } else {
      searchTags.style.display = 'none';
    }
  });
}

if (document.readyState !== 'loading') setupSearch();
else document.addEventListener('DOMContentLoaded', setupSearch);
