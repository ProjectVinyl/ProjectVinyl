import { divmod } from '../../utils/math';
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
      const shown = player.params.path && player.params.id && !player.nonpersistent;

      dom.classList.toggle('hidden', !shown);

      if (!shown) {
        return;
      }

      if (player.audioOnly) {
        time = 0;
      }

      let frameNumber = (time * player.params.framerate) / 20;

      if (frameNumber == lastFrameNumber) {
        return;
      }

      lastFrameNumber = frameNumber;

      let [pageNumber, frameIndex] = divmod(frameNumber, FRAMES_PER_SHEET)

      pageNumber = ('' + (pageNumber + 1)).padStart(3, '0');

      const [frameY, frameX] = divmod(frameIndex, FRAMES_PER_SIDE);

      dom.style.setProperty('--static-frame', `url(/stream/${player.params.path}/${player.params.id}/thumb.png)`);
      dom.style.setProperty('--tiled-frame', player.audioOnly ? '' : `url(/stream/${player.params.path}/${player.params.id}/frames/sheet_${pageNumber}.jpg)`);
      dom.style.setProperty('--frame-x', frameX);
      dom.style.setProperty('--frame-y', frameY);
    }
  };
}
