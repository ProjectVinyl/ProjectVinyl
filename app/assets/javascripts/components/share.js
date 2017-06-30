import { slideOut } from '../ui/slide.js';

const shares = {
  facebook: 'http://www.facebook.com/sharer/sharer.php?href={url}',
  twitter: 'https://twitter.com/intent/tweet?url={url}&via=ProjectVinyl&related=ProjectVInyl,Brony,Music',
  googleplus: 'https://plus.google.com/u/0/share?url={url}&hl=en-GB&caption={title}',
  tumblr: 'https://www.tumblr.com/widgets/share/tool?canonicalUrl={url}&posttype=video&title={title}&content={url}'
};

function updateShareIframe() {
  // FIXME: too much going on here
  const toggle = document.querySelector('#album_share_toggle'),
        type = document.querySelector('#album_share_type'),
        shareField = document.querySelector('#share_field'),
        button = document.querySelector('.action.test'),
        id = button.dataset[(toggle && toggle.checked && type) ? 'first' : 'id'],
        frame = document.querySelector('#embed_preview iframe');

  let typeValue = type && type.value;
  let htm = shareField.dataset.value;
  let extra = '';
  if (toggle && toggle.checked) {
    extra += `?list=${button.dataset.albumId}&index=${typeValue === 'beginning' ? 0 : button.dataset.index}`;
  }

  htm = htm.replace('{id}', id);
  htm = htm.replace('{extra}', extra);

  frame.setAttribute('src', `/embed/${id}${extra}`);
  shareField.value = htm;
}

document.addEventListener('click', event => {
  // Left-click only
  if (event.button !== 0) return;

  const target = event.target.closest('.share-buttons button');
  if (target) {
    let ref = shares[target.dataset.type];
    if (ref) {
      ref = ref.replace(/{url}/g, encodeURIComponent(document.location.href));
      ref = ref.replace(/{title}/g, encodeURIComponent(target.parentNode.dataset.caption));
      // https://medium.com/@jitbit/target-blank-the-most-underestimated-vulnerability-ever-96e328301f4c
      window.open(ref, 'sharer', 'width=500px,height=450px,status=0,toolbar=0,menubar=0,addressbar=0,location=0');
    }
  }
});

function setupShares() {
  // FIXME: same here
  const embedPreview = document.querySelector('#embed_preview'),
        previewButton = document.querySelector('.action.test'),
        shareToggle = document.querySelector('#album_share_toggle'),
        shareType = document.querySelector('#album_share_type');

  if (!embedPreview) return;

  previewButton.addEventListener('click', () => {
    embedPreview.style.display = '';
    updateShareIframe();
    slideOut(slideOut($(previewButton.closest('.slideout'))));
  });

  if (shareToggle) shareToggle.addEventListener('change', updateShareIframe);
  if (shareType) shareType.addEventListener('change', updateShareIframe);
}

if (document.readyState !== 'loading') setupShares();
else document.addEventListener('DOMContentLoaded', setupShares);
