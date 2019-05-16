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
    const scrolledDown = top > player.dom.getBoundingClientRect().bottom;

    if (scrolledDown != floating) {
      floating = scrolledDown;
      
      animating = true;
      
      if (floating) {
        floater.appendChild(player.controls.dom);
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
          animating = false;
        }, 700);
      }
    }
  }
}
