import { uploadForm, defaultCallbacks } from '../../utils/progressform';

function tick(next) {
  const uploader = next();
  if (!uploader) {
    return;
  }

  uploader.begin();
  uploadForm(uploader.form, {
    progress(percentage, duration, message, fill) {
      uploader.update(percentage);
      defaultCallbacks.progress(percentage, duration, message, fill);
      if (next && percentage >= 100) next = tick(next);
    },
    success(data) {
      uploader.complete(data);
      if (next) next = tick(next);
    },
    error(error, message, percentage) {
      uploader.error(error);
      defaultCallbacks.error(error, message, percentage);
      if (next) next = tick(next);
      return error;
    }
  });
}

export function UploadQueue() {
  let running = false;
  const items = [];

  function poke() {
    if (running) return;
    tick(() => {
      let i = 0;
      while (items.length && !(i = items.shift()));
      running = !!i;
      if (running) {
        return i;
      }
    });
  }

  return {
    enqueue: function(me) {
      this.enqueueAll([me]);
    },
    enqueueAll(args) {
      items.push.apply(items, args);
      poke();
    }
  };
}
