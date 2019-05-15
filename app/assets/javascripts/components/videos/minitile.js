/*
 * Creates a tiny preview of a player's video.
 */

export function createMiniTile(player) {
  const canvas = document.createElement('canvas');

  function updateElement() {
    if (player.isReady()) {
      video.currentTime = lastTime;
    }
  }
  
  let video = null;
  let lastTime = -1;
  let updateVideo = () => {
    video = player.createMediaElement();
    
    const loadTime = () => {
      video.removeEventListener('loadeddata', loadTime);
      video.currentTime = lastTime;
    };
    const context = canvas.getContext('2d');

    video.addEventListener('loadeddata', loadTime);
    video.addEventListener('seeked', () => {
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
    });
    
    updateVideo = updateElement;
  };
  
  return {
    dom: canvas,
    draw: time => {
      time -= (time % 5);
      
      if (lastTime !== time) {
        lastTime = time;
        updateVideo();
      }
    }
  };
}
