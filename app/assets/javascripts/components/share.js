import { slideOut } from '../ui/slide.js';
import { jSlim } from '../utils/jslim.js';

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

function setupShares() {
  var frame = document.querySelector('#embed_preview iframe');
  if (!frame) return;
  
  var shareField = document.getElementById('share_field');
  
  // Only used on pages with a linked playlist
  var shareToggle = document.getElementById('album_share_toggle');
  var shareType = document.getElementById('album_share_type');
  //
  
  document.querySelector('.action.test').addEventListener('click', function() {
    frame.parentNode.style.display = '';
    updateShareIframe();
    // Refresh container height - Kind of hacky, imo
    // TODO: replace this
    slideOut(slideOut(frame.closest('.slideout')));
  });
  
  if (shareToggle) {
    shareToggle.addEventListener('change', updateShareIframe);
    shareType.addEventListener('change', updateShareIframe);
  }
  
  function updateShareIframe() {
    var id = getVideoId();
    var src = '/embed/' + id;
    
    var htm = shareField.dataset.value;
    
    htm = htm.replace('{id}', id);
    
    if (shouldIncludeAlbum()) {
      var extra = getAlbumParams();
      htm = htm.replace('{extra}', extra);
      src += extra;
    } else {
      htm = htm.replace('{extra}', '');
    }
    frame.src = src;
    shareField.value = htm;
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
}

jSlim.ready(setupShares);
