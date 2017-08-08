var canvas = null;
var context = null;
let toggle = true;

function noise(ctx) {
  let w = ctx.canvas.width,
      h = ctx.canvas.height,
      idata = ctx.createImageData(w, h),
      buffer32 = new Uint32Array(idata.data.buffer),
      len = buffer32.length;
  for (let i = 0; i < len;) buffer32[i++] = ((255 * Math.random()) | 0) << 24;
  ctx.putImageData(idata, 0, 0);
}

function loop() {
  toggle = !toggle;
  if (!toggle) noise(context);
  requestAnimationFrame(loop);
}

export function setupNoise() {
  if (!canvas) {
    canvas = document.createElement('canvas');
    context = canvas.getContext('2d');
    canvas.width = canvas.height = 256;
    loop();
  }
  return canvas;
};
