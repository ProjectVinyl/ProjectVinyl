import { moDiv } from '../../utils/math';
/*
 * Creates a tiny preview of a player's video.
 */
const FRAMES_PER_SIDE = 20;
const FRAMES_PER_SHEET = Math.pow(FRAMES_PER_SIDE, 2);

export function createMiniTile(player) {
  const dom = player.dom.querySelector('.previewer');
  let lastFrameNumber = -1;
  return {
    dom,
    draw(time) {
      if (player.audioOnly) {
        time = 0;
      }

      let frameNumber = (time * player.params.framerate) / 20;

      if (frameNumber == lastFrameNumber) return;

      lastFrameNumber = frameNumber;

      let [frameIndex, pageNumber] = moDiv(frameNumber, FRAMES_PER_SHEET)

      pageNumber = ('' + (pageNumber + 1)).padStart(3, '0')

      const [frameX, frameY] = moDiv(frameIndex, FRAMES_PER_SIDE);

      dom.style.setProperty('--static-frame', `url(/stream/${player.params.path}/${player.params.id}/thumb.png)`);
      dom.style.setProperty('--tiled-frame', player.audioOnly ? '' : `url(/stream/${player.params.path}/${player.params.id}/frames/sheet_${pageNumber}.jpg)`);
      dom.style.setProperty('--frame-x', frameX);
      dom.style.setProperty('--frame-y', frameY);
    }
  };
}
