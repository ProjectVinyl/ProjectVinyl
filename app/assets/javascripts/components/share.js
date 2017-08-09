import { slideOut } from '../ui/slide';
import { jSlim } from '../utils/jslim';

const shares = {
  facebook: 'http://www.facebook.com/sharer/sharer.php?href={url}',
  twitter: 'https://twitter.com/intent/tweet?url={url}&via=ProjectVinyl&related=ProjectVInyl,Brony,Music',
  googleplus: 'https://plus.google.com/u/0/share?url={url}&hl=en-GB&caption={title}',
  tumblr: 'https://www.tumblr.com/widgets/share/tool?canonicalUrl={url}&posttype=video&title={title}&content={url}'
};

// https://medium.com/@jitbit/target-blank-the-most-underestimated-vulnerability-ever-96e328301f4c
function popOpen(url, title, props) {
  var other = window.open('_blank', title, props);
  other.opener = null;
  other.location = url;
}

jSlim.on(document, 'click', '.share-buttons button', function(e) {
  // Left-click only
  if (e.which != 1 && e.button !== 0) return;
  var ref = shares[this.dataset.type];
  if (ref) {
    ref = ref.replace(/{url}/g, encodeURIComponent(document.location.href));
    ref = ref.replace(/{title}/g, encodeURIComponent(this.parentNode.dataset.caption));
    popOpen(ref, 'sharer', 'width=500px,height=450px,status=0,toolbar=0,menubar=0,addressbar=0,location=0');
  }
});

jSlim.ready(() => {
  const embedPreview = document.querySelector('#embed_preview');
  let frame;
  
  if (!embedPreview) return;
  
  document.querySelector('.action.test').addEventListener('click', function() {
    embedPreview.style.display = '';
    this.parentNode.removeChild(this);
    embedPreview.innerHTML = '<iframe style="max-width:100%;" width="560px" height="100%" frameborder="0"></iframe>';
    frame = embedPreview.firstChild;
    updateShareIframe();
    // Refresh container height - Kind of hacky, imo
    // TODO: replace this
    slideOut(slideOut(embedPreview.closest('.slideout')));
  });
  
  const shareField = document.getElementById('share_field');
  
  // Only used on pages with a linked playlist
  const shareToggle = document.getElementById('album_share_toggle');
  const shareType = document.getElementById('album_share_type');
  //
  
  if (shareToggle) {
    shareToggle.addEventListener('change', updateShareIframe);
    shareType.addEventListener('change', updateShareIframe);
  }
  
  function updateShareIframe() {
    const id = getVideoId();
    
    let src = '/embed/' + id;
    let htm = shareField.dataset.value;
    
    htm = htm.replace('{id}', id);
    
    if (shouldIncludeAlbum()) {
      let extra = getAlbumParams();
      htm = htm.replace('{extra}', extra);
      src += extra;
    } else {
      htm = htm.replace('{extra}', '');
    }
    shareField.value = htm;
    
    if (frame) frame.src = src;
  }
  
  function getVideoId() {
    return shareField.dataset[shouldIncludeAlbum() ? 'first' : 'id'];
  }
  
  function shouldIncludeAlbum() {
    return shareToggle && shareToggle.checked;
  }

  function getAlbumParams() {
    var index = shareType.value == 'beginning' ? 0 : shareField.dataset.albumIndex;
    return '?list=' + shareField.dataset.albumId + '&index=' + index;
  }
});
