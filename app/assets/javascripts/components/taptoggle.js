export function TapToggler(owner) {
  let hoverTimeout = null;
  let touching = false;
  let hoverFlag = 0;
  
  const toggler = {
    update: function() {
      touching = true;

      owner.classList.add('hover');
      hoverFlag++;

      if (hoverTimeout) {
        clearTimeout(hoverTimeout);
      }

      hoverTimeout = setTimeout(() => {
        owner.classList.add('hover');
        hoverTimeout = null;
        hoverFlag = 0;
      }, 1700);
    },
    touching: _ => touching,
    interactable: _ => !touching || hoverFlag > 1
  };
  
  owner.addEventListener('touchstart', toggler.update);
  
  return owner.toggler = toggler;
}
