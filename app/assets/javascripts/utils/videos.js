const VIDEO_ELEMENT = document.createElement('video');

export function canPlayType(mime) {
  return !!(mime = VIDEO_ELEMENT.canPlayType(mime)).length && mime !== 'no';
}

export function errorMessage(video) {
  if (!video.error) {
    switch (video.networkState) {
      case HTMLMediaElement.NETWORK_NO_SOURCE:
        return 'Network Error';
    }
    return 'Unknown Error';
  }
  switch (video.error.code) {
    case video.error.MEDIA_ERR_ABORTED: return 'Playback Aborted';
    case video.error.MEDIA_ERR_NETWORK: return 'Network Error';
    case video.error.MEDIA_ERR_DECODE: return 'Feature not Supported';
    case video.error.MEDIA_ERR_SRC_NOT_SUPPORTED: return 'Codec not supported';
    default: return 'Unknown Error';
  }
}

export function errorPresent(video) {
  return (video.error && video.error.code !== video.error.MEDIA_ERR_ABORTED)
      || (video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE)
      || (video.networkState === HTMLMediaElement.NETWORK_LOADING);
}
