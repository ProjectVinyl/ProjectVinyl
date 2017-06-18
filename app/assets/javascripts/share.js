(function() {
  window.shares = {
    facebook: 'http://www.facebook.com/sharer/sharer.php?href={url}',
    twitter: 'https://twitter.com/intent/tweet?url={url}&via=ProjectVinyl&related=ProjectVInyl,Brony,Music',
    googleplus: 'https://plus.google.com/u/0/share?url={url}&hl=en-GB&caption={title}',
    tumblr: 'https://www.tumblr.com/widgets/share/tool?canonicalUrl={url}&posttype=video&title={title}&content={url}'
  };
  
  $doc.on('click', '.share-buttons button', function() {
    var ref = window.shares[this.dataset.type];
    if (ref) {
      ref = ref.replace(/{url}/g, encodeURIComponent(document.location.href));
      ref = ref.replace(/{title}/g, encodeURIComponent(this.parentNode.dataset.caption));
      window.open(ref, 'sharer', 'width=500px,height=450px,status=0,toolbar=0,menubar=0,addressbar=0,location=0');
    }
  });
})();

