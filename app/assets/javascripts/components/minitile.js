
export function createMiniTile(player) {
  const canvas = document.createElement('canvas');
  let video = null;
  let lastTime = -1;
  return {
    dom: canvas,
    draw: time => {
      time -= (time % 5);
      
      if (lastTime !== time) {
        lastTime = time;
        
        if (!video) {
          video = player.createMediaElement();
          const context = canvas.getContext('2d');
          const loadTime = () => {
            video.removeEventListener('loadeddata', loadTime);
            video.currentTime = time;
          };
          
          video.addEventListener('loadeddata', loadTime);
          video.addEventListener('seeked', () => {
           context.drawImage(video, 0, 0, canvas.width, canvas.height);
          });
        } else if (player.isReady()) {
          video.currentTime = time;
        }
      }
    }
  }
}
