/*
 * Initialises basic video playback funtionality.
 *
 * Copyright Project Vinyl Foundation 2017
*/
import { ajax } from '../utils/ajax';
import { scrollTo } from '../ui/scroll';
import { ContextMenu } from '../ui/contextmenu';
import { halt, Key, makeExtensible } from '../utils/misc';
import { errorMessage, errorPresent } from '../utils/videos';
import { jSlim } from '../utils/jslim';
import { cookies } from '../utils/cookies';
import { TapToggler } from './taptoggle';
import { toHMS } from '../utils/duration';
import { PlayerControls } from './playercontrols';
import { setupNoise } from './noise';

let fadeControl = null;
let fullscreenPlayer = null;

function controlsFade() {
  if (fullscreenPlayer) {
    fullscreenPlayer.controls.hide();
  }
  fadeControl = null;
}

function restartConstrolsFade() {
  fullscreenPlayer.controls.show();
  if (fadeControl === null) fadeControl = setTimeout(controlsFade, 1000);
}

Player.setFullscreen = function(sender) {
  document.removeEventListener('mousemove', restartConstrolsFade);
  if (sender) {
    document.addEventListener('mousemove', restartConstrolsFade);
  }
  fullscreenPlayer = sender;
}

// FIXME: wtf
// Secret identifier to prevent senders from responding to their own messages
// (there is no gaurantee that the current window will not get a message it just dispatched.
// There may also be other players on the same page that need to respond to each other)
function getNextMessageSeed() {
  var old = parseInt(localStorage['::activeplayer'] || '0');
  return ((old + 1) % 3).toString();
}

function sendMessage(sender) {
  if (sender.__sendMessages) {
    sender.__seed = getNextMessageSeed();
    localStorage.setItem('::activeplayer', sender.__seed);
  }
}

function attachMessageListener(sender) {
  window.addEventListener('storage', event => {
    if (event.key === '::activeplayer' && event.newValue !== sender.__seed) {
      sender.pause();
    }
  });
}

function canGen(child) {
  return !child || child.classList.contains('playlist');
}

function Player() { }
makeExtensible(Player);

Player.isFullscreen = function() {
  return document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
};
Player.onFullscreen = function(func) {
  document.addEventListener('webkitfullscreenchange', func);
  document.addEventListener('mozfullscreenchange', func);
  document.addEventListener('fullscreenchange', func);
};

Player.speeds = [
  {name: 'Double', value: 2},
  {name: '1.5x', value: 1.5},
  {name: '1.25x', value: 1.25},
  {name: 'Normal', value: 1},
  {name: '0.5x', value: 0.5},
  {name: '0.25x', value: 0.25}
];

//TODO: Move to server-side view
Player.generate = function(holder) {
  holder.insertAdjacentHTML('afterbegin', `
<div class="player">
  <span class="playing"></span>
  <span class="error"><span class="error-message"></span></span>
  <span class="suspend" style="display:none"><i class="fa fa-pulse fa-spinner"></i></span>
  <span class="pause resize-holder">
    <span class="playback"></span>
    <h1 class="resize-target" style="display:none;"><a target="_blank" href="'/view/${holder.dataset.source}-${holder.dataset.title}" class="title">${holder.dataset.title}</a></h1>
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
<ul class="contextmenu transitional hidden"></ul>`);
};

Player.onFullscreen(function() {
  if (fullscreenPlayer) {
    fullscreenPlayer.fullscreen(Player.isFullscreen());
  }
});

function readyVideo(sender) {
  var video;
  if (sender.audioOnly && sender.source) {
    video = document.createElement('audio');
    video.src = '/stream/' + sender.source + sender.mime[0];
    video.type = sender.mime[1];
  } else {
    video = sender.createVideoElement();
  }
  
  if (sender.time) {
    if (player.isReady()) {
      video.currentTime = sender.time;
    } else {
      const setTime = () => {
        video.currentTime = sender.time;
        video.removeEventListener('canplay', setTime);
      };
      video.addEventListener('canplay', setTime);
    }
  }
  
  const sources = video.querySelectorAll('source');
  if (sources.length) sources[sources.length - 1].addEventListener('error', e => sender.error(e));
  video.addEventListener('abort', e => sender.error(e));
  video.addEventListener('error', e => sender.error(e));
  
  video.addEventListener('pause', () => sender.pause());
  video.addEventListener('play', () => {
    sender.player.classList.add('playing');
    sender.player.classList.remove('stopped');
    sender.player.classList.remove('paused');
    sender.player.classList.remove('error');
    video.loop = !!sender.__loop;
    sendMessage(sender);
    sender.volume(video.volume, video.muted);
  });
  
  video.addEventListener('ended', () => {
    if (sender.__autoplay) {
      sender.navTo(document.querySelector('#playlist_next'));
    } else if (sender.pause()) {
      sender.player.classList.add('stopped');
    }
  });
  
  let suspendTimer = null;
  const suspended = function() {
    if (suspendTimer) return;
    suspendTimer = setTimeout(() => this.style.display = 'block', 3000);
  }
  
  video.addEventListener('suspend', suspended);
  video.addEventListener('waiting', suspended);
  
  video.addEventListener('volumechange', () => {
    sender.volume(video.volume, video.muted || video.volume === 0);
  });
  
  video.addEventListener('timeupdate', () => {
    if (suspendTimer) {
      clearTimeout(suspendTimer);
      suspendTimer = null;
    }
    sender.track(video.currentTime, parseFloat(video.duration) || 0);
  });
  
  return video;
}

Player.prototype = {
  // FIXME: way too much happening here
  constructor: function(el, standalone) {
    this.__sendMessages = !standalone;
    
    this.embedded = false;
    this.audioOnly = !!el.dataset.audio;
    this.source = el.dataset.video || el.dataset.audio;
    this.video = null;
    this.mime = (el.dataset.mime || '.mp4|video/m4v').split('|');
    this.time = parseInt(el.dataset.time || '0') || 0;
    this.title = el.dataset.title;
    this.artist = el.dataset.artist;
    
    if (canGen(el.firstElementChild)) Player.generate(el);
    
    this.dom = el;
    this.suspend = el.querySelector('.suspend');
    
    this.player = el.querySelector('.player');
    this.player.error = this.player.querySelector('.error');
    this.player.error.message = this.player.error.querySelector('.error-message');
    this.player.getPlayerObj = () => this;
    
    this.heading = el.querySelector('h1 .artist');
    
    this.contextmenu = new ContextMenu(el.querySelector('.contextmenu'), this.dom);
    
    this.controls = el.querySelector('.controls');
    if (this.controls) {
      this.controls = new PlayerControls(this, this.controls);
    }
    
    el.addEventListener('click', ev => {
      if (ev.button !== 0) return;
      if (!this.contextmenu.hide(ev)) {
        if (!this.player.classList.contains('playing') || this.dom.toggler.interactable()) {
          if (this.dom.playlist && this.dom.playlist.classList.contains('visible')) {
            this.dom.playlist.classList.toggle('visible');
          } else {
            this.togglePlayback();
          }
        }
      }
    });
    
    const activeTouches = [];
    let tapped = false;
    new TapToggler(this.dom);
    
    el.addEventListener('touchstart', ev => {
      if (fullscreenPlayer === ev.target) {
        if (activeTouches.length > 0) {
          return halt(ev);
        }
      }
      
      if (tapped) {
        this.fullscreen(!Player.isFullscreen());
        halt(ev);
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
    
    document.addEventListener('keydown', ev => {
      if (ev.which === Key.SPACE) {
        if (!document.querySelector('input:focus, textarea:focus')) {
          if (this.video) {
            this.togglePlayback();
            halt(ev);
          }
        }
      }
    });
    
    this.contextmenu.addItem('Loop', this.setLoop(false), val => {
      val(this.setLoop(!this.__loop));
    });
    
    this.contextmenu.addItem('Speed', this.changeSpeed(3), val => {
      val(this.changeSpeed(this.__speed + 1));
    });
    
    this.contextmenu.addItem('Autoplay', this.setAutoplay(!!cookies.get('autoplay')), val => {
      val(this.setAutoplay(!this.__autoplay));
      cookies.set('autoplay', this.__autoplay);
    });
    
    this.__autostart = !!cookies.get('autostart');
    this.contextmenu.addItem('Autostart', this.__autostart, val => {
      val(this.__autostart = !this.__autostart);
      cookies.set('autostart', this.__autostart);
    });
    
    if (el.dataset.playlistId) {
      this.setPlaylist(el.dataset.playlistId, el.dataset.playlistIndex);
    }
    
    if (el.dataset.embed) {
      this.setEmbed();
    }
    
    const selected = document.querySelector('.playlist a.selected');
    if (selected) scrollTo(selected, document.querySelector('.playlist .scroll-container'));
    
    attachMessageListener(this);
    // at the bottom
    resize(el);
    
    if (this.__autostart || el.dataset.autoplay || el.dataset.resume === 'true') {
      this.checkstart();
    }
    
    return this;
  },
  setEmbed: function() {
    this.embedded = true;
    
    const h1 = this.player.querySelector('.pause h1');
    const link = h1.querySelector('.pause h1 a');
    
    h1.style.pointerEvents = 'initial';
    h1.style.display = '';
    link.addEventListener('click', ev => ev.stopPropagation());
    link.addEventListener('mouseover', () => {
      if (this.video && this.video.currentTime > 0) {
        link.href = '/view/' + this.source + '-' + this.title + '?resume=' + this.video.currentTime;
      }
    });
  },
  setPlaylist: function(albumId, albumIndex) {
    this.album = {
      id: albumId,
      index: albumIndex
    };
    
    this.dom.playlist = document.querySelector('.playlist');
    this.dom.playlist.link = document.createElement('div');
    this.dom.playlist.link.classList.add('playlist-toggle');
    this.dom.playlist.link.innerHTML = '<i class="fa fa-list"/>';
    this.dom.appendChild(this.dom.playlist.link);
    
    this.dom.playlist.link.addEventListener('click', ev => {
      this.dom.playlist.classList.toggle('visible');
      halt(ev);
    });
    
    this.dom.playlist.addEventListener('click', ev => {
      if (ev.button !== 0) return;
      const target = ev.target.closest('.items a, #playlist_next, #playlist_prev');
      this.navTo(target);
      halt(ev);
    });
  },
  navTo: function(sender) {
    if (sender) {
      return ajax.get('view' + sender.getAttribute('href')).json(json => {
        const next = document.querySelector('#playlist_next');
        const prev = document.querySelector('#playlist_prev');
        
        this.redirect = target.href;
        this.loadAttributesAndRestart(json);
        
        var selected = document.querySelector('.playlist a.selected');
        if (selected) selected.classList.remove('selected');
        selected = document.querySelector('.playlist a[data-id="' + json.id + '"]');
        selected.classList.add('selected');
        scrollTo(selected, document.querySelector('.playlist .scroll-container'));
        
        if (this.embedded) {
          if (next && json.next) next.href = json.next;
          if (prev && json.prev) prev.href = json.prev;
        } else {
          if (next) {
            if (json.next) {
              next.href = json.next;
            } else {
              next.parentNode.removeChild(next);
              document.querySelector('.buff-right').classList.remove('buff-right');
            }
          }
          if (prev) {
            if (json.prev) {
              prev.href = json.prev;
            } else {
              prev.parentNode.removeChild(prev);
            }
          }
        }
      });
    }
    
    document.location.href.replace(sender.href);
  },
  changeSpeed: function(speed) {
    this.__speed = speed % Player.speeds.length;
    speed = Player.speeds[speed] || Player.speeds[3];
    if (this.video) this.video.playbackRate = speed.value;
    return speed.name;
  },
  fullscreen: function(on) {
    this.controls.fullscreen.innerHTML = '<i class="fa fa-' + (on ? 'restore' : 'arrows-alt') + '"></i>';
    if (!on) this.player.querySelector('.playing').style.cursor = '';
    if (!Player.requestFullscreen) return false;
    if (fadeControl !== null) clearTimeout(fadeControl);
    if (fullscreenPlayer && fullscreenPlayer !== this) {
      fullscreenPlayer.fullscreen(false);
    }
    if (on) {
      Player.requestFullscreen.apply(this.dom);
      Player.setFullscreen(this);
      fadeControl = setTimeout(controlsFade, 1000);
    } else if (fullscreenPlayer) {
      if (this.redirect) {
        if (this.video) {
          this.redirect += (this.redirect.indexOf('?') >= 0 ? '&' : '?') + 't=' + this.video.currentTime;
        }
        document.location.replace(this.redirect);
        return;
      }
      Player.setFullscreen(null);
      Player.exitFullscreen.apply(document);
      this.controls.show();
    }
    Player.setFullscreen(on ? this : null);
    return on;
  },
  setAutoplay: function(on) {
    this.__autoplay = on;
    if (on) {
      this.setLoop(false);
    }
    return on;
  },
  setLoop: function(on) {
    this.__loop = on;
    if (this.video) this.video.loop = on;
    return on;
  },
  checkstart: function() {
    if (!this.video) this.start();
  },
  loadAttributesAndRestart: function(attr) {
    this.dom.style.backgroundImage = "url('/cover/" + attr.source + ".png')";
    this.heading.title.textContent = this.title = attr.title;
    this.heading.artist.textContent = this.artist = attr.artist;
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
    if (data) this.loadURL(URL.createObjectURL(data));
  },
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
  isReady: function() {
    return this.video && this.video.readyState === 4;
  },
  createVideoElement: function() {
    const video = document.createElement('video');
    
    if (!this.source || this.source === '0') return video;
    
    if (typeof this.source === 'string' && this.source.indexOf('blob') === 0) {
      video.setAttribute('src', this.source);
      return video;
    }
    
    video.innerHTML = '<source src="/stream/' + this.source + '.webm" type="video/webm"></source><source src="/stream/' + this.source + this.mime[0] + '" type="' + this.mime[1] + '"></source>';
    
    return video;
  },
  start: function() {
    if (!this.video) {
      this.video = readyVideo(this);
      this.player.querySelector('.playing').appendChild(this.video);
      this.volume(this.video.volume, this.video.muted);
    }
    
    if (this.video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE) {
      this.video.load();
    }
    
    this.video.play();
  },
  stop: function() {
    this.pause();
    this.jump(0);
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
    if (errorPresent(this.video)) {
      const message = errorMessage(this.video);
      this.player.classList.add('stopped');
      this.player.classList.add('error');
      this.player.error.message.innerText = message;
      if (!this.noise) {
        this.noise = setupNoise();
        this.player.error.appendChild(this.noise);
      }
      console.warn(message);
    }
    console.log(e);
  },
  togglePlayback: function() {
    if (this.player.classList.contains('playing')) {
      return this.pause();
    }
    this.start();
  },
  track: function(time, duration) {
    const percentFill = (time / duration) * 100;
    
    this.controls.track.bob.style.left = percentFill + '%';
    this.controls.track.fill.style.right = (100 - percentFill) + '%';
    
    this.suspend.style.display = 'none';
  },
  jump: function(progress) {
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    const duration = parseFloat(this.video.duration) || 0;
    const time = duration * progress;
    this.video.currentTime = time;
    this.track(time, duration);
  },
  volume: function(volume, muted) {
    if (this.controls.volume.indicator) this.controls.volume.indicator.setAttribute('class', 'fa fa-volume-' + getVolumeIcon(muted ? 0 : volume));
    if (this.video) this.video.volume = volume;
    if (muted) volume = 0;
    volume *= 100;
    this.controls.volume.slider.bob.style.bottom = volume + '%';
    this.controls.volume.slider.fill.style.top = (100 - volume) + '%';
  },
  muteUnmute: function() {
    this.checkstart();
    this.video.muted = !this.video.muted;
    this.volume(this.video.volume, this.video.muted);
  }
};

function getVolumeIcon(level) {
  if (level < 0) return 'off';
  if (level < 0.33) return 'down';
  if (level < 0.66) return 'mid';
  return 'up';
}

function resize(obj) {
  obj.style.marginBottom = '';          // 16/9 aspect ratio
  obj.style.height = (obj.clientWidth * 9 / 16) + 'px';
}

jSlim.ready(() => {
  jSlim.all('.video', v => {
    if (!v.dataset.pending && !v.classList.contains('unplayable')) (new Player()).constructor(v);
  });
  
  window.addEventListener('resize', () => {
    jSlim.all('.video', resize);
  });
});

export { Player };
