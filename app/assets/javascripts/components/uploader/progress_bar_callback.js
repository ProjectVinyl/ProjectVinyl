
export function initProgressor(...el) {
  if (el.length > 1) {
    return ofAll(el.map(single));
  }

  return single(el[0]);
}

export function ofAll(progressors) {
  function trigger(method) {
    return data => {
      progressors.forEach(a => {
        if (a[method]) {
          a[method](data);
        }
      });
    }
  }
  return {
    begin: trigger('begin'),
    update: trigger('update'),
    complete: trigger('complete'),
    error: trigger('error'),
  };
}

function single(el) {
  return {
    begin() {
      el.classList.add('uploading');
      el.classList.add('pending');
    },
    update(percentage) {
      el.classList.add('uploading');
      el.querySelector('.progress .fill').style.setProperty('--status-progress', `${percentage}%`);
      el.classList.toggle('pending', percentage >= 100);
    },
    complete(data) {
      el.classList.remove('pending');
      el.classList.remove('uploading');
      
      if (!data.success) {
        el.classList.add('error');
      }
    },
    error() {
      el.classList.add('error');
      el.classList.remove('pending');
    }
  };
}