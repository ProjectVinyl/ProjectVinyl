function iterateEvents(mode, ender, change) {
  ['mouseup', 'touchend', 'touchcancel'].forEach(t => document[mode + 'EventListener'](t, ender));
  ['mousemove', 'touchmove'            ].forEach(t => document[mode + 'EventListener'](t, change));
}

export function Slider(dom, jump, grab) {
  const grabCallback = (change, end) => {
    const ender = () => {
      iterateEvents('remove', ender, change);
      end();
    };
    
    iterateEvents('add', ender, change);
  };
  var grabEvent = ev => {
    grab(ev, grabCallback);
    ev.preventDefault();
  };
  
  dom.bob = dom.querySelector('.bob');
  dom.fill = dom.querySelector('.fill');
  
  dom.addEventListener('click', jump);
  dom.bob.addEventListener('mousedown', grabEvent);
  dom.bob.addEventListener('touchstart', grabEvent);
}
