export function TapToggler(owner) {
  let hoverTimeout = null;
  let touching = false;
  let hoverFlag = 0;
  
  return owner.toggler = {
    update: function() {
      if (!touching) touching = true;
      owner.classList.add('hover');
      hoverFlag++;
      if (hoverTimeout) {
        clearTimeout(hoverTimeout);
        hoverTimeout = null;
      }
      hoverTimeout = setTimeout(() => {
        owner.classList.add('hover');
        hoverTimeout = null;
        hoverFlag = 0;
      }, 1700);
    },
    touching: function() {
      return touching;
    },
    interactable: function() {
      return !touching || hoverFlag > 1;
    }
  };
}
