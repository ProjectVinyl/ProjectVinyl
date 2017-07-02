/*
 * Initialises basic video playback funtionality.
 *
 * Copyright Project Vinyl Foundation 2017
*/

import { fetchJson } from '../utils/requests.js';
import { scrollTo } from '../ui/scroll.js';
import { Key } from '../utils/misc.js';
import { jSlim } from '../utils/jslim.js';

const VIDEO_ELEMENT = document.createElement('video');
const aspect = 16 / 9;
let fadeControl = null;

function controlsFade() {
  if (Player.fullscreenPlayer) {
    Player.fullscreenPlayer.controls.style.opacity = 0;
    Player.fullscreenPlayer.player.querySelector('.playing').style.cursor = 'none';
  }
  fadeControl = null;
}

function attachMessageListener(sender) {
  window.addEventListener('storage', event => {
    if (event.key === '::activeplayer' && event.newValue !== sender.__seed) {
      sender.pause();
    }
  });
}

function sendMessage(sender) {
  if (sender.__sendMessages) {
    // FIXME: wtf
    // Secret identifier to prevent senders from responding to their own messages
    // (there is no gaurantee that the current window will not get a message it just dispatched. There may also be other players on the same page that need to respond to each other)
    sender.__seed = '' + ((parseInt(localStorage['::activeplayer'] || '0', 10) + 1) % 3);
    localStorage.setItem('::activeplayer', sender.__seed);
  }
}

function canGen(child) {
  return !child || child.classList.contains('playlist');
}

function Player() { }

/* Standardise fullscreen API */
(function(p) {
  Player.requestFullscreen = p.requestFullscreen || p.mozRequestFullScreen || p.msRequestFullscreen || p.webkitRequestFullscreen || function() {};
  Player.exitFullscreen = document.exitFullscreen || document.mozCancelFullScreen || document.msExitFullscreen || document.webkitExitFullscreen || function() {};
  Player.isFullscreen = function() {
    return document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
  };
})(Element.prototype);

Player.onFullscreen = function(func) {
  document.addEventListener('webkitfullscreenchange', func);
  document.addEventListener('mozfullscreenchange', func);
  document.addEventListener('fullscreenchange', func);
};

Player.canPlayType = function(mime) {
  return !!(mime = VIDEO_ELEMENT.canPlayType(mime)).length && mime !== 'no';
};

Player.speeds = [
  {name: 'Double', value: 2},
  {name: '1.5x', value: 1.5},
  {name: '1.25x', value: 1.25},
  {name: 'Normal', value: 1},
  {name: '0.5x', value: 0.5},
  {name: '0.25x', value: 0.25}
];

Player.createVideoElement = function(player) {
  const video = document.createElement('video');
  
  if (!player.source || player.source === '0') return video;
  
  if (typeof player.source === 'string' && player.source.indexOf('blob') === 0) {
    video.setAttribute('src', player.source);
    return video;
  }
  
  video.innerHTML = `
    <source src="/stream/${player.source}.webm" type="video/webm"></source>
    <source src="/stream/${player.source}${player.mime[0]}" type="${player.mime[1]}"></source>`;
  
  return video;
};

Player.errorMessage = function(video) {
  if (!video.error) {
    switch (video.networkState) {
      case HTMLMediaElement.NETWORK_NO_SOURCE:
        return 'Network Error';
    }
    return 'Unknown Error';
  }
  switch (video.error.code) {
    case video.error.MEDIA_ERR_ABORTED: return 'Playback Aborted';
    case video.error.MEDIA_ERR_NETWORK: return 'Network Error';
    case video.error.MEDIA_ERR_DECODE: return 'Feature not Supported';
    case video.error.MEDIA_ERR_SRC_NOT_SUPPORTED: return 'Codec not supported';
    default: return 'Unknown Error';
  }
};

Player.errorPresent = function(video) {
  return (video.error && video.error.code !== video.error.MEDIA_ERR_ABORTED) || (video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE);
};

Player.isready = function(video) {
  return video.readyState === 4;
};

Player.noise = (function() {
  var canvas = null, ctx = null;
  var toggle = true;
  
  function noise(ctx) {
    var w = ctx.canvas.width,
        h = ctx.canvas.height,
        idata = ctx.createImageData(w, h),
        buffer32 = new Uint32Array(idata.data.buffer),
        len = buffer32.length,
        i = 0;
    for (; i < len;) buffer32[i++] = ((255 * Math.random()) | 0) << 24;
    ctx.putImageData(idata, 0, 0);
  }
  
  function loop() {
    toggle = !toggle;
    if (toggle) return requestAnimationFrame(loop);
    noise(ctx);
    requestAnimationFrame(loop);
  }
  
  return function setupNoise() {
    if (canvas !== null) return canvas;
    canvas = document.createElement('canvas');
    ctx = canvas.getContext('2d');
    canvas.width = canvas.height = 256;
    loop();
    return canvas;
  };
})();

//TODO: Move to server-side view
Player.generate = function(holder) {
  holder.insertAdjacentHTML('afterbegin', `
<div class="player">
  <span class="playing"></span>
  <span class="error"><span class="error-message"></span></span>
  <span class="suspend" style="display:none"><i class="fa fa-pulse fa-spinner"></i></span>
  <span class="pause resize-holder">
    <span class="playback"></span>
    <h1 class="resize-target" style="display:none;"><a class="title"></a></h1>
  </span>
</div>
<div class="controls playback-controls">
  <ul>
    <li class="track">
      <span class="fill"></span>
      <div class="previewer"></div>
      <span class="bob"></span>
    </li>
    <li class="icon volume">
      <span class="indicator"><i class="fa fa-volume-up"></i></span>
      <div class="slider">
        <span class="fill"></span>
        <span class="bob"></span>
      </div>
    </li>
    <li class="icon fullscreen">
      <span class="indicator"><i class="fa fa-arrows-alt"></i></span>
    </li>
  </ul>
</div>
<ul class="contextmenu"></ul>`);
};

Player.onFullscreen(function() {
  if (Player.fullscreenPlayer) {
    Player.fullscreenPlayer.fullscreen(Player.isFullscreen());
  }
});

Player.extend = function(Child, overrides) {
  var keys = Object.keys(overrides);
  Child.prototype = new this();
  Child.Super = this.prototype;
  Child.extend = this.extend;
  for (var i = keys.length; i--;) {
    Child.prototype[keys[i]] = overrides[keys[i]];
  }
};

Player.prototype = {
  // FIXME: way too much happening here
  constructor: function(el, standalone) {
    if (canGen(el.firstElementChild)) Player.generate(el);
    
    this.__sendMessages = !standalone;
    this.dom = el;
    this.player = el.querySelector('.player');
    this.player.error = this.player.querySelector('.error');
    this.player.error.message = this.player.error.querySelector('.error-message');
    this.suspend = el.querySelector('.suspend');
    this.contextmenu = el.querySelector('.contextmenu');
    this.contextmenu.unset = 1;
    this.player.getPlayerObj = () => this;
    
    this.video = null;
    this.mime = (el.dataset.mime || '.mp4|video/m4v').split('|');
    this.controls = el.querySelector('.controls');
    this.source = el.dataset.video;
    
    if (!this.source) {
      this.source = el.dataset.audio;
      this.audioOnly = true;
      this.preview = document.createElement('img');
      this.preview.src = `/cover/${this.source}-small.png`;
    } else {
      this.preview = document.createElement('canvas');
    }
    
    this.time = el.dataset.time;
    
    // at the bottom
    resize(el);
    
    const h1Title = el.querySelector('h1 .title');
    const h1Artist = el.querySelector('h1 .artist');
    
    this.title = el.dataset.title;
    if (h1Title) h1Title.textContent = this.title;
    this.artist = el.dataset.artist;
    if (this.artist && h1Artist) h1Artist.textContent = this.artist;
    
    new TapToggler(this.dom);
    
    el.addEventListener('click', ev => {
      if (ev.button !== 0) return;
      
      if (!this.removeContext(ev)) {
        if (!this.player.classList.contains('playing') || this.dom.toggler.interactable()) {
          if (this.dom.playlist && this.dom.playlist.classList.contains('visible')) {
            this.dom.playlist.classList.toggle('visible');
          } else {
            this.toggleVideo();
          }
        }
      }
    });
    
    el.addEventListener('contextmenu', ev => this.showContext(ev));
    
    const activeTouches = [];
    let tapped = false;
    
    el.addEventListener('touchstart', ev => {
      if (Player.fullscreenPlayer === ev.target) {
        if (activeTouches.length > 0) {
          this.halt(ev);
          return;
        }
      }
      
      if (tapped) {
        this.fullscreen(!Player.isFullscreen());
        this.halt(ev);
        clearTimeout(tapped);
        tapped = null;
        return;
      }
      
      tapped = setTimeout(() => tapped = null, 500);
      activeTouches.push({identifier: ev.identifier});
    });
    
    function onTouchEvent(ev) {
      for (let i = 0; i < activeTouches; i++) {
        if (activeTouches[i].identifier === ev.identifier) {
          activeTouches.splice(i, 1);
        }
      }
    }
    
    el.addEventListener('touchmove', onTouchEvent);
    el.addEventListener('touchend', onTouchEvent);
    el.addEventListener('touchcancel', onTouchEvent);
    
    this.__loop = false;
    this.__speed = 3;
    this.contextmenu.addEventListener('click', this.halt);
    this.addContext('Loop', false, val => {
      val(this.loop(!this.__loop));
    });
    this.addContext('Speed', this.speed(this.__speed), val => {
      this.__speed = (this.__speed + 1) % Player.speeds.length;
      val(this.speed(this.__speed));
    });
    
    document.addEventListener('click', ev => { if (ev.button === 0) this.removeContext(ev); });
    document.addEventListener('keydown', ev => {
      if (ev.which === Key.SPACE) {
        if (!document.querySelector('input:focus,textarea:focus')) {
          if (this.video) {
            this.toggleVideo();
            this.halt(ev);
          }
        }
      }
    });
    
    if (this.controls) {
      this.controls.track = this.controls.querySelector('.track');
      this.controls.track.addEventListener('mousedown', ev => {
        if (!this.removeContext(ev)) {
          this.checkstart();
          this.jump(ev);
        }
      });
      this.controls.track.bob = this.controls.querySelector('.track .bob');
      this.controls.track.fill = this.controls.querySelector('.track .fill');
      this.controls.track.bob.addEventListener('mousedown', ev => {
        if (!this.removeContext(ev)) this.startChange(ev);
      });
      this.controls.track.bob.addEventListener('touchstart', ev => {
        this.removeContext(ev);
        this.startChange(ev);
      });
      this.controls.track.preview = el.querySelector('.track .previewer');
      this.controls.track.preview.appendChild(this.preview);
      this.controls.track.addEventListener('mousemove', ev => {
        this.drawPreview(this.evToProgress(ev));
      });
      this.controls.volume = this.controls.querySelector('.volume');
      this.controls.volume.addEventListener('click', ev => {
        if (ev.button !== 0) return;
        if (!this.removeContext(ev)) {
          if (this.controls.volume.toggler.interactable()) {
            this.muteUnmute();
          }
        }
      });
      new TapToggler(this.controls.volume);
      this.controls.volume.addEventListener('touchstart', ev => {
        this.controls.volume.toggler.update(ev);
        this.halt(ev);
      });
      
      this.controls.volume.bob = this.controls.querySelector('.volume .bob');
      this.controls.volume.fill = this.controls.querySelector('.volume .fill');
      this.controls.volume.bob.addEventListener('mousedown', ev => {
        if (!this.removeContext(ev)) this.startChangeVolume(ev);
      });
      this.controls.volume.bob.querySelector('touchstart', ev => {
        this.removeContext(ev);
        this.startChangeVolume(ev);
      });
      this.controls.volume.slider = this.controls.querySelector('.volume .slider');
      this.controls.volume.slider.addEventListener('mousedown', ev => {
        if (!this.removeContext(ev)) {
          this.checkstart();
          this.changeVolume(ev);
        }
      });
      this.controls.fullscreen = this.controls.querySelector('.fullscreen .indicator');
      this.controls.querySelector('.fullscreen').addEventListener('click', ev => {
        if (ev.button !== 0) return;
        if (!this.removeContext(ev)) {
          this.fullscreen(!Player.isFullscreen());
          this.halt(ev);
        }
      });
      this.controls.volume.slider.addEventListener('click', this.halt);
      this.controls.querySelector('li').addEventListener('click', this.halt);
    }
    
    attachMessageListener(this);
    
    if (el.dataset.embed) {
      this.setEmbed();
      jSlim.ready(function() {
        const selected = document.querySelector('.playlist a.selected');
        if (selected) scrollTo(selected, document.querySelector('.playlist .scroll-container'));
      });
    }
    
    if (el.dataset.playlistId) {
      this.setPlaylist(el.dataset.playlistId, el.dataset.playlistIndex);
    }
    
    if (el.dataset.autoplay) {
      this.checkstart();
      // FIXME: extract cookie fetch code to some util
      this.addContext('Autoplay', this.autoplay(!document.cookie.replace(/(?:(?:^|.*;\s*)autoplay\s*=\s*([^;]*).*$)|^.*$/, '$1')), val => {
        val(this.__autoplay = !this.__autoplay);
        document.cookie = 'autoplay=' + (this.__autoplay ? ';' : '1;');
      });
    } else if (el.dataset.resume === 'true') {
      this.checkstart();
    }
    
    return this;
  },
  removeContext: function(ev) {
    if (ev.which === 1 && this.contextmenu.style.display === 'table') {
      this.contextmenu.style.opacity = '';
      setTimeout(() => this.contextmenu.style.display = '', 100);
      return 1;
    }
    return 0;
  },
  showContext: function(ev) {
    let y = ev.pageY;
    let x = ev.pageX;
    
    const vWidth = document.documentElement.clientWidth;
    const vHeight = document.documentElement.clientHeight;
    
    if (x + this.contextmenu.clientWidth > vWidth) x = vWidth - this.contextmenu.clientWidth;
    if (y + this.contextmenu.clientHeight + 10 >= vHeight) y = vHeight - this.contextmenu.clientHeight - 10;
    
    this.contextmenu.style.top = `${y - (this.dom.getBoundingClientRect().top + pageYOffset)}px`;
    this.contextmenu.style.left = `${x - (this.dom.getBoundingClientRect().left + pageXOffset)}px`;
    this.contextmenu.style.display = 'table';
    this.contextmenu.style.opacity = '1';
    
    this.halt(ev);
  },
  setEmbed: function() {
    const h1 = this.player.querySelector('.pause h1');
    const link = h1.querySelector('.pause h1 a');
    
    h1.style.pointerEvents = 'initial';
    h1.style.display = '';
    
    link.target = '_blank';
    link.href = `/view/${this.source}-${this.title}`;
    
    link.addEventListener('mouseover', () => {
      if (this.video && this.video.currentTime > 0) {
        link.href = `/view/${this.source}-${this.title}?resume=${this.video.currentTime}`;
      }
    });
    
    link.addEventListener('click', ev => ev.stopPropagation());
  },
  setPlaylist: function(albumId, albumIndex) {
    this.album = {
      id: albumId,
      index: albumIndex
    };
    
    this.dom.playlist = document.querySelector('.playlist');
    this.dom.playlist.link = document.createElement('div');
    this.dom.playlist.link.class = 'playlist-toggle';
    this.dom.playlist.link.innerHTML = '<i class="fa fa-list"/>';
    this.dom.append(this.dom.playlist.link);

    this.dom.playlist.link.addEventListener('click', ev => {
      this.dom.playlist.classList.toggle('visible');
      this.halt(ev);
    });
    
    // FIXME: cookie parsing
    this.addContext('Autoplay', this.autoplay(!document.cookie.replace(/(?:(?:^|.*;\s*)autoplay\s*=\s*([^;]*).*$)|^.*$/, '$1')), val => {
      val(this.__autoplay = !this.__autoplay);
      document.cookie = `autoplay=${this.__autoplay ? ';' : '1;'}`;
    });
    
    this.dom.playlist.addEventListener('click', ev => {
      if (ev.button !== 0) return;
      
      const target = ev.target.closest('.items a, #playlist_next, #playlist_prev');
      if (target) {
        fetchJson('GET', `/ajax/view${target.href}`).then(response => response.json()).then(json => {
          const playlistNext = document.querySelector('#playlist_next');
          const playlistPrev = document.querySelector('#playlist_prev');
          let selectedItem = document.querySelector('.playlist a.selected');
          
          this.redirect = target.href;
          this.loadAttributesAndRestart(json);
          
          if (json.next) playlistNext.href = json.next;
          if (json.prev) playlistPrev.href = json.prev;
          
          if (selectedItem) selectedItem.classList.remove('selected');
          selectedItem = document.querySelector(`.playlist a[data-id=${json.id}]`);
          selectedItem.classList.add('selected');
          scrollTo(selectedItem, document.querySelector('.playlist .scroll-container'));
        });
      }
      
      this.halt(ev);
    });
  },
  addContext: function(title, initial, callback) {
    const item = document.createElement('li');
    item.innerHTML = `<div class="label">${title}</div>`;
    
    const value = document.createElement('div');
    value.classList.add('value');
    item.appendChild(value);
    
    function val(s) {
      value.innerHTML = typeof s === 'boolean' ? s ? '<i class="fa fa-check" />' : '' : s;
    }
    
    val(initial);
    item.addEventListener('click', () => callback(val));
    this.contextmenu.appendChild(item);
  },
  speed: function(speed) {
    speed = Player.speeds[speed] || Player.speeds[3];
    if (this.video) this.video.playbackRate = speed.value;
    return speed.name;
  },
  fullscreen: function(on) {
    this.onfullscreen(on);
    if (!Player.requestFullscreen) return false;
    if (fadeControl !== null) clearTimeout(fadeControl);
    if (Player.fullscreenPlayer && Player.fullscreenPlayer !== this) {
      Player.fullscreenPlayer.fullscreen(false);
    }
    if (on) {
      Player.requestFullscreen.apply(this.dom);
      Player.fullscreenPlayer = this;
      fadeControl = setTimeout(controlsFade, 1000);
    } else if (Player.fullscreenPlayer) {
      if (this.redirect) {
        if (this.video) {
          this.redirect += (this.redirect.indexOf('?') >= 0 ? '&' : '?') + 't=' + this.video.currentTime;
        }
        document.location.replace(this.redirect);
        return;
      }
      Player.fullscreenPlayer = null;
      Player.exitFullscreen.apply(document);
      this.controls.style.opacity = '';
    }
    Player.fullscreenPlayer = on ? this : null;
    return on;
  },
  onfullscreen: function(on) {
    this.controls.fullscreen.innerHTML = on ? '<i class="fa fa-restore"></i>' : '<i class="fa fa-arrows-alt"></i>';
    if (!on) this.player.querySelector('.playing').style.cursor = '';
  },
  autoplay: function(on) {
    this.__autoplay = on;
    if (on) {
      this.loop(false);
    }
    return on;
  },
  loop: function(on) {
    this.__loop = on;
    if (this.video) this.video.loop = on;
    return on;
  },
  checkstart: function() {
    if (!this.video) this.start();
  },
  loadAttributesAndRestart: function(attr) {
    this.dom.style.backgroundImage = `url('/cover/${attr.source}.png')`;
    this.dom.querySelector('h1 .title').textContent = this.title = attr.title;
    this.dom.querySelector('h1 .artist').textContent = this.artist = attr.artist;
    this.source = attr.source;
    this.mime = attr.mime;
    this.audioOnly = attr.audioOnly;
    if (this.video) {
      this.video.parentNode.removeChild(this.video);
      this.video = null;
    }
    this.start();
  },
  load: function(data) {
    this.loadURL(URL.createObjectURL(data));
  },
  // FIXME: almost completely duplicated, likely can simply
  // change client code to just use one or other
  loadURL: function(url) {
    this.audioOnly = false;
    if (this.source) {
      URL.revokeObjectURL(this.source);
    }
    if (url) {
      this.source = url;
      if (this.audioOnly) {
        this.video = null;
        this.start();
      } else {
        if (!this.video) this.start();
        this.video.src = this.source;
      }
      this.video.load();
    }
  },
  start: function() {
    let video;
    
    if (!this.video) {
      if (this.audioOnly && this.source) {
        video = document.createElement('audio');
        video.src = `/stream/${this.source}${this.mime[0]}`;
        video.type = this.mime[1];
      } else {
        video = Player.createVideoElement(this);
      }
      
      this.video = video;
      
      if (this.time && this.time !== '0') {
        if (Player.isready(this.video)) {
          this.video.currentTime = parseInt(this.time, 10);
        } else {
          const t = parseInt(this.time, 10);
          const setTime = () => {
            this.currentTime = t;
            this.removeEventListener('canplay', setTime);
          };
          this.video.addEventListener('canplay', setTime);
        }
      }
      this.player.querySelector('.playing').appendChild(this.video);
      
      video.addEventListener('pause', () => this.pause());
      video.addEventListener('play', () => {
        this.player.classList.add('playing');
        this.player.classList.remove('stopped');
        this.player.classList.remove('paused');
        this.player.classList.remove('error');
        this.video.loop = !!this.__loop;
        sendMessage(this);
        this.volume(video.volume, video.muted);
      });
      video.addEventListener('abort', e => this.error(e));
      video.addEventListener('error', e => this.error(e));
      
      const sources = video.querySelectorAll('source');
      if (sources.length) sources[sources.length - 1].addEventListener('error', e => this.error(e));
      
      video.addEventListener('ended', () => {
        if (this.__autoplay) {
          // FIXME: more duplication
          const next = document.querySelector('#playlist_next');
          const prev = document.querySelector('#playlist_prev');
          let selected = document.querySelector('.playlist a.selected');
          
          if (next) {
            if (Player.fullscreenPlayer === this || this.album) {
              // ew
              fetchJson('GET', `/ajax/view${next.href}`).then(response => response.json()).then(json => {
                this.redirect = next.href;
                this.loadAttributesAndRestart(json);
                if (json.next) {
                  next.href = json.next;
                } else {
                  next.parentNode.removeChild(next);
                  document.querySelector('.buff-right').classList.remove('buff-right');
                }
                if (json.prev) {
                  prev.href = json.prev;
                } else {
                  prev.parentNode.removeChild(prev);
                }
                if (selected) selected.classList.remove('selected');
                selected = document.querySelector(`.playlist a[data-id=${json.id}]`);
                selected.classList.add('selected');
                scrollTo(selected, document.querySelector('.playlist .scroll-container'));
              });
            } else {
              document.location.replace(next.href);
            }
          }
        } else {
          if (this.pause()) this.player.classList.add('stopped');
        }
      });
      
      let suspendTimer = null;
      function suspended() {
        if (suspendTimer) return;
        suspendTimer = setTimeout(() => this.style.display = 'block', 3000);
      }
      
      video.addEventListener('suspend', suspended.bind(this));
      video.addEventListener('waiting', suspended.bind(this));
      
      video.addEventListener('volumechange', () => {
        this.volume(this.video.volume, this.video.muted || this.video.volume === 0);
      });
      
      video.addEventListener('timeupdate', () => {
        if (suspendTimer) {
          clearTimeout(suspendTimer);
          suspendTimer = null;
        }
        this.track(this.video.currentTime, parseFloat(this.video.duration) || 0);
      });
      
      this.volume(this.video.volume, video.muted);
    }
    
    if (this.video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE) {
      this.video.load();
    }
    
    this.video.play();
  },
  stop: function() {
    this.pause();
    this.changetrack(0);
    this.video.parentNode.removeChild(this.video);
    this.video = null;
    this.suspend.style.display = 'none';
  },
  pause: function() {
    this.player.classList.remove('playing');
    this.player.classList.add('paused');
    if (this.video) this.video.pause();
    this.suspend.style.display = 'none';
    return true;
  },
  error: function(e) {
    this.pause();
    if (Player.errorPresent(this.video)) {
      const message = Player.errorMessage(this.video);
      this.player.classList.add('stopped');
      this.player.classList.add('error');
      this.player.error.message.textContent = message;
      if (!this.noise) {
        this.noise = Player.noise();
        this.player.error.appendChild(this.noise);
      }
      console.warn(message);
    }
    console.log(e);
  },
  toggleVideo: function() {
    if (!this.player.classList.contains('playing')) {
      this.start();
    } else {
      this.pause();
    }
  },
  track: function(time, duration) {
    const percentFill = (time / duration) * 100;
    
    this.controls.track.bob.style.left = `${percentFill}%`;
    this.controls.track.fill.style.right = `${100 - percentFill}%`;
    
    if (this.dom.toggler.touching()) {
      this.controls.track.preview.style.left = `${percentFill}%`;
      this.controls.track.preview.dataset.time = this.descriptive(time);
    }
    
    this.suspend.style.display = 'none';
  },
  changetrack: function(progress) {
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    const duration = parseFloat(this.video.duration) || 0;
    const time = duration * progress;
    this.video.currentTime = time;
    this.track(time, duration);
  },
  jump: function(ev) {
    const progress = this.evToProgress(ev);
    this.changetrack(progress);
    if (ev.touches) {
      this.drawPreview(progress);
    }
    this.halt(ev);
  },
  evToProgress: function(ev) {
    let x = ev.pageX;
    if (!x && ev.touches) {
      x = ev.touches[0].pageX || 0;
    }
    
    x -= this.controls.track.getBoundingClientRect().left + pageXOffset;
    if (x < 0) x = 0;
    if (x > this.controls.track.clientWidth) x = this.controls.track.clientWidth;
    return x / this.controls.track.clientWidth;
  },
  startChange: function(ev) {
    this.checkstart();
    this.dom.classList.add('tracking');
    
    const func = ev => this.jump(ev);
    const ender = () => {
      ['mouseup', 'touchend', 'touchcancel'].forEach(t => document.removeEventListener(t, ender));
      ['mousemove', 'touchmove'            ].forEach(t => document.removeEventListener(t, func));
      this.dom.classList.remove('tracking');
    };
    
    // FIXME: damn that's a lot of events
    ['mouseup', 'touchend', 'touchcancel'].forEach(t => document.addEventListener(t, ender));
    ['mousemove', 'touchmove'            ].forEach(t => document.addEventListener(t, func));

    this.halt(ev);
  },
  // FIXME: almost exact duplicate of above
  // Except for the *volume* slider!
  // Should probably combine them
  startChangeVolume: function(ev) {
    this.checkstart();
    this.dom.classList.add('voluming');
    
    const func = ev => this.changeVolume(ev);
    const ender = () => {
      ['mouseup', 'touchend', 'touchcancel'].forEach(t => document.removeEventListener(t, ender));
      ['mousemove', 'touchmove'            ].forEach(t => document.removeEventListener(t, func));
      this.dom.classList.remove('voluming');
    };
    
    ['mouseup', 'touchend', 'touchcancel'].forEach(t => document.addEventListener(t, ender));
    ['mousemove', 'touchmove'            ].forEach(t => document.addEventListener(t, func));
    
    this.halt(ev);
  },
  changeVolume: function(ev) {
    const height = this.controls.volume.slider.clientHeight;
    if (height === 0) return;
    
    let y = ev.pageY;
    if (!y && ev.touches) {
      y = ev.touches[0].pageY || 0;
    }
    y -= this.controls.volume.slider.getBoundingClientRect().top + window.pageYOffset;
    if (y < 0) y = 0;
    if (y > height) y = height;
    y = height - y;
    this.volume(y / height, y === 0);
    this.halt(ev);
  },
  // FIXME: why is it necessary to also stopPropagation?
  // FIXME: why is this function part of the prototype?
  // Utility function, used all over the place. Move it if you like.
  halt: function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
  },
  volume: function(volume, muted) {
    const indicator = this.dom.querySelector('.volume .indicator i');
    if (indicator) indicator.class = muted ? 'fa fa-volume-off' : volume < 0.33 ? 'fa fa-volume-down' : volume < 0.66 ? 'fa fa-volume-mid' : 'fa fa-volume-up';
    if (this.video) this.video.volume = volume;
    if (muted) volume = 0;
    volume *= 100;
    this.controls.volume.bob.style.bottom = `${volume}%`;
    this.controls.volume.fill.style.top = `${100 - volume}%`;
  },
  muteUnmute: function() {
    this.checkstart();
    this.video.muted = !this.video.muted;
    this.volume(this.video.volume, this.video.muted);
  },
  // FIXME: Highly ironic name
  //Convert a time to hh:mm:ss
  descriptive: function(time) {
    const times = [];
    time = Math.floor(time);
    while (time >= 60) {
      times.push(time % 60);
      time = Math.floor(time / 60);
    }
    times.push(time);
    if (times.length < 2) times.push(0);
    return times.reverse().join(':');
  },
  drawPreview: function(progress) {
    if (!this.video) return;
    
    const duration = parseInt(this.video.duration, 10) || 0;
    let time = duration * progress;
    
    this.controls.track.preview.style.left = `${(time / duration) * 100}%`;
    this.controls.track.preview.dataset.time = this.descriptive(time);
    
    if (!this.audioOnly) {
      // TODO: wtf
      time = time -= time % 5;
      
      if (this.preview && this.preview.time !== time) {
        this.preview.time = time;
        
        if (!this.preview.video) {
          const tempVid = this.preview.video = Player.createVideoElement(this);
          const canvas = this.preview;
          const context = this.preview.getContext('2d');
          tempVid.addEventListener('loadeddata', function loadTime() {
            tempVid.currentTime = time;
            tempVid.removeEventListener('loadeddata', loadTime);
          });
          tempVid.addEventListener('seeked', () => {
            context.drawImage(tempVid, 0, 0, canvas.width, canvas.height);
          });
        } else {
          if (Player.isready(this.preview.video)) {
            this.preview.video.currentTime = time;
          }
        }

      }
    }

  }
};

function TapToggler(owner) {
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

function resize(obj) {
  // aspect is defined at the top of the file
  obj.style.marginBottom = '';
  obj.style.height = `${obj.clientWidth / aspect}px`;
}

function removeContext() {
  const fakeEvent = { which: 1 };
  jSlim.all('.player', p => {
    if (p.getPlayerObj) p.getPlayerObj().removeContext(fakeEvent);
  });
}

jSlim.ready(() => {
  jSlim.all('.video', v => {
    if (!v.dataset.pending && !v.classList.contains('unplayable')) (new Player()).constructor(v);
  });
  
  window.addEventListener('resize', () => {
    jSlim.all('.video', resize);
  });
  
  window.addEventListener('resize', removeContext);
  window.addEventListener('blur', removeContext);
  
  document.addEventListener('mousemove', () => {
    if (Player.fullscreenPlayer) {
      Player.fullscreenPlayer.controls.style.opacity = 1;
      Player.fullscreenPlayer.player.querySelector('.playing').style.cursor = '';
      if (fadeControl === null) fadeControl = setTimeout(controlsFade, 1000);
    }
  });
});

export { Player };
