/*
 * Enables functionality for a draggable slider control.
 */

function iterateEvents(mode, ender, change) {
  ['mouseup', 'touchend', 'touchcancel'].forEach(t => document[mode + 'EventListener'](t, ender));
  ['mousemove', 'touchmove'            ].forEach(t => document[mode + 'EventListener'](t, change));
}

export function Slider(dom, jump, grab) {
  const grabCallback = (change, end) => {
    const ender = () => {
      dom.classList.remove('interacting');
      iterateEvents('remove', ender, change);
      end();
    };

    dom.classList.add('interacting');
    iterateEvents('add', ender, change);
  };
  const grabEvent = ev => {
    grab(ev, grabCallback);
    ev.preventDefault();
  };
  
  dom.bob = dom.querySelector('.bob');
  dom.fill = dom.querySelector('.fill');

  dom.addEventListener('click', jump);
  dom.bob.addEventListener('mousedown', grabEvent);
  dom.bob.addEventListener('touchstart', grabEvent);
  dom.touch = () => {
    dom.dispatchEvent(new CustomEvent("transitive", {bubbles: true}));
  };
}

export function SliderSensitive(dom) {
  let interactingTimeout;
  dom.addEventListener('transitive', () => {
    dom.classList.add('hover');
    if (interactingTimeout) {
      interactingTimeout = clearTimeout(interactingTimeout);
    }
    interactingTimeout = setTimeout(() => {
      dom.classList.remove('hover');
    }, 500);
  });
}
