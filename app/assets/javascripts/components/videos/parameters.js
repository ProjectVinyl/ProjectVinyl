
export function playerHeader(sender) {
  const heading = sender.dom.querySelector('h1 .title');
  if (heading) heading.addEventListener('mouseover', () => {
    if (sender.video && sender.video.currentTime) {
      heading.href = `/videos/${sender.params.id}-${sender.params.title}?resume=${sender.video.currentTime}`;
    }
  });

  return heading;
}

export function fillRequiredParams(params, el) {
  params.type = params.type || 'video';
  params.embedded = params.embedded || !!el.closest('.featured');
  params.mime = params.mime || ['.mp4', 'video/m4v'];
  params.time = params.time || 0;
  return params;
}

export function readParams(el) {
  const params = fillRequiredParams(JSON.parse(unescape((el.dataset.source || '{}').replace('+', ' '))), el);
  delete el.dataset.source;
  return params;
}
