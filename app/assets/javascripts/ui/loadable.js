import { jSlim } from '../utils/jslim';

jSlim.on(document, 'click', '.loadable a[data-remote]', function(event) {
  const target = this.closest('.loadable');

  target.classList.add('loading');
});

jSlim.on(document, 'fetch:complete', '.loadable a[data-remote]', function(event) {
  const response = event.detail;
  const target = this.closest('.loadable');

  response.text().then(text => {
    target.classList.remove('loading');
    target.innerHTML = text;
  });
});
