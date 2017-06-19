import { slideOut } from './uislide.js';

const shares = {
  facebook: 'http://www.facebook.com/sharer/sharer.php?href={url}',
  twitter: 'https://twitter.com/intent/tweet?url={url}&via=ProjectVinyl&related=ProjectVInyl,Brony,Music',
  googleplus: 'https://plus.google.com/u/0/share?url={url}&hl=en-GB&caption={title}',
  tumblr: 'https://www.tumblr.com/widgets/share/tool?canonicalUrl={url}&posttype=video&title={title}&content={url}'
};
  
function updateShareIframe() {
  var toggle = $('#album_share_toggle');
  var type = $('#album_share_type').val();
  var share_field = $('#share_field');
  var htm = share_field.attr('data-value');
  var button = $('.action.test');
  var id = button.attr(toggle.length && toggle[0].checked && type == 'beginning' ? 'data-first' : 'data-id');
  console.log(id);
  var extra = '';
  if (toggle.length && toggle[0].checked) {
    extra += '?list=' + button.attr('data-album-id') + '&index=';
    extra += type == 'beginning' ? 0 : button.attr('data-index');
  }
  htm = htm.replace('{id}', id);
  htm = htm.replace('{extra}', extra);
  $('#embed_preview iframe').attr('src', '/embed/' + id + extra);
  share_field.val(htm);
}

$(document).on('click', '.share-buttons button', function() {
  var ref = shares[this.dataset.type];
  if (ref) {
    ref = ref.replace(/{url}/g, encodeURIComponent(document.location.href));
    ref = ref.replace(/{title}/g, encodeURIComponent(this.parentNode.dataset.caption));
    window.open(ref, 'sharer', 'width=500px,height=450px,status=0,toolbar=0,menubar=0,addressbar=0,location=0');
  }
});

$(function() {
  var embedPreview = $('#embed_preview');
  if (embedPreview.length) {
    $('.action.test').on('click', function() {
      embedPreview.css('display', '');
      updateShareIframe();
      slideOut(slideOut($(this).closest('.slideout')));
    });
    
    $('#album_share_toggle, #album_share_type').on('change', function() {
      updateShareIframe();
    });
  }
});
