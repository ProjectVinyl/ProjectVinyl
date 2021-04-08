let shoveRate;
let shoveTimer;

export function shove(e, scrollContext) {
  if (e.clientY <= 0) {
    startShoving(e.clientY, scrollContext);
  } else if (e.clientY >= scrollContext.clientHeight) {
    startShoving(e.clientY - scrollContext.clientHeight, scrollContext);
  } else {
    stopShoving();
  }
}

function startShoving(rate, scrollContext) {
  if (!shoveTimer) {
    shoveTimer = setInterval(() => {
      scrollContext.scrollTop += shoveRate;
    });
  }
  shoveRate = rate;
  
}

export function stopShoving() {
  if (shoveTimer) {
    shoveTimer = clearInterval(shoveTimer);
  }
}
