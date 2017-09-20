export function pushUrl(newUrl) {
  if (window.history && window.history.pushState && newUrl != document.location.href) {
    window.history.pushState({
      path: newUrl
    }, '', newUrl);
  }
}
