
new MutationObserver(mutations => {
  mutations.forEach(mutation => {
    mutation.addedNodes.forEach(node => {
      if (node.tagName == 'IFRAME' && node.classList.contains('twitter-timeline-rendered')) {
        console.log(node);
        node.addEventListener('load', injectCss);
      }
    });
  });
}).observe(document.body, {
  childList: true
});

function injectCss(e) {
  const doc = e.target.contentDocument || e.target.document;
  if (doc && !doc.head.querySelector('.pv-injected')) {
    const style = document.querySelector('#timeline-styling');
    style.classList.add('pv-injected');
    doc.head.insertAdjacentHTML('beforeend', style.outerHTML);
  }
}
