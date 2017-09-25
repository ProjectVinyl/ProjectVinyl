import { uploadForm } from '../utils/progressform';

function tick(next) {
  const uploader = next();
  if (!uploader) return;
  uploader.tab.classList.add('loading');
  uploader.tab.classList.add('waiting');
  uploadForm(uploader.form, {
    progress: (message, fill, percentage) => {
      uploader.update(percentage);
      if (next && percentage >= 100) next = tick(next);
    },
    success: data => {
      uploader.complete(data.ref);
      if (next) next = tick(next);
    },
    error: (message, error) => {
      uploader.error();
      message.innerText = error;
      if (next) next = tick(next);
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
      while (items.length && !(i = items.shift()).isReady());
      running = i && i.isReady();
      if (running) return i;
    });
  }
  
  return {
    enqueue: function(me) {
      if (me.isReady()) enqueueAll([me]);
    },
    enqueueAll: function(args) {
      items.push.apply(items, args);
      poke();
    }
  };
}
