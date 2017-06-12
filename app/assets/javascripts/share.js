var shares = {
  'facebook': 'http://www.facebook.com/sharer/sharer.php?href={url}',
  'twitter': 'https://twitter.com/intent/tweet?url={url}&via=ProjectVinyl&related=ProjectVInyl,Brony,Music',
  'googleplus': 'https://plus.google.com/u/0/share?url={url}&hl=en-GB&caption={title}',
  'tumblr': 'https://www.tumblr.com/widgets/share/tool?canonicalUrl={url}&posttype=video&title={title}&content={url}'
};

$('.share-buttons button').on('click', function() {
  var ref = shares[$(this).attr('data-type')];
  if (ref) {
    ref = ref.replace(/{url}/g, encodeURIComponent(document.location.href));
    ref = ref.replace(/{title}/g, encodeURIComponent($(this).parent().attr('data-caption')));
    window.open(ref, 'sharer', 'width=500px,height=450px,status=0,toolbar=0,menubar=0,addressbar=0,location=0');
  }
});