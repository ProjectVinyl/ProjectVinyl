function noise(canvas, ctx) {
  let w = canvas.width,
      h = canvas.height,
      idata = ctx.createImageData(w, h),
      buffer32 = new Uint32Array(idata.data.buffer),
      len = buffer32.length;

  for (let i = 0; i < len;) {
    buffer32[i++] = ((255 * Math.random()) | 0) << 24;
  }
 
  ctx.putImageData(idata, 0, 0);
}

export function setupNoise(parent) {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  
  let running = true;
  
  canvas.width = canvas.height = 256;
  parent.appendChild(canvas);
  
  function loop() {
    noise(canvas, ctx);
    if (running) {
      requestAnimationFrame(loop);
    }
  }
  
  loop();
  
  return {
    destroy: () => {
      canvas.parentNode.removeChild(canvas);
      running = false;
    }
  };
}
