/*
 * Floating player functionality.
 * Currently only provides controls support.
 */
import { scrollContext } from '../../ui/reflow';
import { throttleFunc } from '../../ui/infiniscroll';

export function attachFloater(player) {
  const floater = document.querySelector('.floating-player');
  let animating;
  let top = 0;

  if (!floater) {
    return;
  }

  const scrollingContext = scrollContext();
  setInterval(throttleFunc(() => {
    if (!animating && scrollingContext.scrollTop != top) {
      top = scrollingContext.scrollTop;

      onScroll();
    }
  }), 10);

  let floating;

  function onScroll() {
    if (!player.video) return;

    const scrolledDown = player.dom.getBoundingClientRect().bottom < 20;

    if (scrolledDown != floating) {
      floating = scrolledDown;

      animating = true;

      if (floating) {
        floater.appendChild(player.controls.dom);
        floater.querySelector('.player').appendChild(player.video);
        floater.style.setProperty('--aspect-ratio', player.dom.style.getPropertyValue('--aspect-ratio'));
        setTimeout(() => {
          floater.classList.remove('hiding');

          setTimeout(() => {
            animating = false;
          }, 700);
        }, 10);
      } else {
        floater.classList.add('hiding');

        setTimeout(() => {
          player.dom.querySelector('.control-ref').insertAdjacentElement('beforebegin', player.controls.dom);
          player.player.media.appendChild(player.video);
          animating = false;
        }, 700);
      }
    }
  }

  return floater;
}
