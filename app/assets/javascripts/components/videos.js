/*
 * Initialises basic video playback funtionality.
 *
*/
import { ajax } from '../utils/ajax';
import { scrollTo } from '../ui/scroll';
import { ContextMenu } from '../ui/contextmenu';
import { halt, Key } from '../utils/misc';
import { errorMessage, errorPresent } from '../utils/videos';
import { jSlim, bindAll } from '../utils/jslim';
import { isFullscreen, onFullscreenChange } from '../utils/fullscreen';
import { cookies } from '../utils/cookies';
import { TapToggler } from './taptoggle';
import { toHMS } from '../utils/duration';
import { PlayerControls } from './playercontrols';
import { setupNoise } from './noise';

const speeds = [
  {name: 'Double', value: 2},
  {name: '1.5x', value: 1.5},
  {name: '1.25x', value: 1.25},
  {name: 'Normal', value: 1},
  {name: '0.5x', value: 0.5},
  {name: '0.25x', value: 0.25}
];

let fadeControl = null;
let fullscreenPlayer = null;

function fadeOut() {
  if (fullscreenPlayer) fullscreenPlayer.controls.show();
  if (fadeControl !== null) clearTimeout(fadeControl);
  fadeControl = setTimeout(() => {
    if (fullscreenPlayer) fullscreenPlayer.controls.hide();
    fadeControl = null;
  }, 1000);
}

function setFullscreen(sender) {
  fullscreenPlayer = sender;
  document.removeEventListener('mousemove', fadeOut);
  if (sender) {
    document.addEventListener('mousemove', fadeOut);
    fadeOut();
  }
}

function sendMessage(sender) {
  if (sender.__sendMessages) {
    let id = parseInt(localStorage['::activeplayer'] || '0');
    sender.__seed = ((id + 1) % 3).toString();
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

function readyVideo(sender) {
  let sender.createMediaElement()
  
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
  
  let suspendTimer = null;
  function suspended() {
    if (!suspendTimer) suspendTimer = setTimeout(() => sender.suspend.style.display = 'block', 3000);
  }
  
  bindAll(video, {
    abort: e => sender.error(e),
    error: e => sender.error(e),
    pause: () => sender.pause(),
    play: () => {
      sender.player.dataset.state = 'playing';
      video.loop = !!sender.__loop;
      sendMessage(sender);
      sender.volume(video.volume, video.muted);
    },
    ended: () => {
      if (sender.__autoplay) {
        const next = document.querySelector('#playlist_next');
        if (next) {
          if (!sender.embedded && !fullscreenPlayer) return sender.click();
          sender.navTo(next);
        }
      } else if (sender.pause()) {
        sender.player.dataset.state = 'stopped';
      }
    },
    suspend: suspended,
    waiting: suspended,
    volumechange: () => {
      sender.volume(video.volume, video.muted || video.volume === 0);
    },
    timeupdate: () => {
      if (suspendTimer) {
        clearTimeout(suspendTimer);
        suspendTimer = null;
      }
      sender.track(video.currentTime, parseFloat(video.duration) || 0);
    }
  });
  
  return video;
}

function Player() { }
Player.prototype = {
  // FIXME: way too much happening here
  constructor: function(el, standalone) {
    this.dom = el;
    this.embedded = !!el.dataset.embed;
    this.audioOnly = !!el.dataset.audio;
    this.source = el.dataset.video || el.dataset.audio;
    this.video = null;
    this.mime = (el.dataset.mime || '.mp4|video/m4v').split('|');
    this.time = parseInt(el.dataset.time || '0') || 0;
    this.title = el.dataset.title;
    
    this.suspend = el.querySelector('.suspend');
    
    this.player = el.querySelector('.player');
    this.player.media = this.player.querySelector('.playing');
    this.player.error = this.player.querySelector('.error');
    this.player.error.message = this.player.error.querySelector('.error-message');
    this.player.getPlayerObj = () => this;
    
    this.playlist = document.querySelector('.playlist');
    
    this.heading = el.querySelector('h1 .title');
    if (this.heading) {
      this.heading.addEventListener('mouseover', () => {
        if (this.video && this.video.currentTime) {
          this.heading.href = '/view/' + this.source + '-' + this.title + '?resume=' + this.video.currentTime;
        }
      });
    }
    
    this.contextmenu = new ContextMenu(el.querySelector('.contextmenu'), this.dom);
    this.controls = new PlayerControls(this, el.querySelector('.controls'));
    
    this.__sendMessages = !standalone;
    if (this.__sendMessages) attachMessageListener(this);
    
    let activeTouches = [];
    let tapped = false;
    new TapToggler(this.dom);
    
    function onTouchEvent(ev) {
      activeTouches = activeTouches.filter(t => t.identifier !== ev.identifier)
    }
    
    bindAll(el, {
      click: ev => {
        if (ev.button !== 0) return;
        if (!this.contextmenu.hide(ev)) {
          let target = ev.target.closest('.items a, #playlist_next, #playlist_prev');
          if (target) return this.navTo(target);
          
          if (this.playlist && ev.target.closest('.playlist-toggle')) {
            this.playlist.classList.toggle('visible');
            return;
          }
          
          if (this.player.dataset.state != 'playing' || this.dom.toggler.interactable()) {
            
            if (this.playlist && this.playlist.classList.contains('visible')) {
              this.playlist.classList.remove('visible');
              return;
            }
            
            this.togglePlayback();
          }
        }
      }
      touchstart: ev => {
        if (fullscreenPlayer === this && activeTouches.length) return halt(ev);
        
        if (!tapped) {
          tapped = setTimeout(() => tapped = null, 500);
          activeTouches.push({identifier: ev.identifier});
          return;
        }
        
        clearTimeout(tapped);
        tapped = null;
        this.fullscreen(!isFullscreen());
        halt(ev);
      }
      touchmove: onTouchEvent,
      touchend, onTouchEvent,
      touchcancel: onTouchEvent
    });
    
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
      cookies.set('autoplay', val(this.setAutoplay(!this.__autoplay)));
    });
    
    this.__autostart = !!cookies.get('autostart');
    this.contextmenu.addItem('Autostart', this.__autostart, val => {
      cookies.set('autostart', val(this.__autostart = !this.__autostart));
    });
    
    const selected = document.querySelector('.playlist a.selected');
    if (selected) scrollTo(selected, document.querySelector('.playlist .scroll-container'));
    
    // at the bottom
    resize(el);
    
    if (this.__autostart || el.dataset.autoplay || el.dataset.resume === 'true') {
      this.play();
    }
    
    return this;
  },
  navTo: function(sender) {
    ajax.get('view' + sender.getAttribute('href')).json(json => {
      const next = document.querySelector('#playlist_next');
      const prev = document.querySelector('#playlist_prev');
      
      this.redirect = target.href;
      this.loadAttributesAndRestart(json);
      
      var selected = document.querySelector('.playlist a.selected');
      if (selected) selected.classList.remove('selected');
      selected = document.querySelector('.playlist a[data-id="' + json.id + '"]');
      selected.classList.add('selected');
      scrollTo(selected, document.querySelector('.playlist .scroll-container'));
      
      if (next && json.next) next.href = json.next;
      if (prev && json.prev) prev.href = json.prev;
      
      if (!this.embedded) {
        if (next && !json.next) {
          next.parentNode.removeChild(next);
          document.querySelector('.buff-right').classList.remove('buff-right');
        }
        if (prev && !json.prev) {
          prev.parentNode.removeChild(prev);
        }
      }
    });
  },
  fullscreen: function(on) {
    this.controls.fullscreen.innerHTML = '<i class="fa fa-' + (on ? 'restore' : 'arrows-alt') + '"></i>';
    this.player.media.style.cursor = on ? 'none' : '';
    
    if (fullscreenPlayer && fullscreenPlayer !== this) fullscreenPlayer.fullscreen(false);
    if (fullscreenPlayer && !on) {
      document.exitFullscreen();
      this.controls.show();
      if (this.redirect) {
        if (this.video) {
          this.redirect += (this.redirect.indexOf('?') >= 0 ? '&' : '?') + 't=' + this.video.currentTime;
        }
        document.location.replace(this.redirect);
      }
    }
    
    if (on) this.dom.requestFullscreen();
    setFullscreen(on ? this : null);
    return on;
  },
  changeSpeed: function(speed) {
    this.__speed = speed % speeds.length;
    speed = speeds[speed] || speeds[3];
    if (this.video) this.video.playbackRate = speed.value;
    return speed.name;
  },
  setAutoplay: function(on) {
    this.__autoplay = on;
    if (on) this.setLoop(false);
    return on;
  },
  setLoop: function(on) {
    this.__loop = on;
    if (this.video) this.video.loop = on;
    return on;
  },
  loadAttributesAndRestart: function(attr) {
    this.dom.style.backgroundImage = "url('/cover/" + attr.source + ".png')";
    this.source = attr.source;
    this.mime = attr.mime;
    this.title = attr.title;
    this.audioOnly = attr.audioOnly;
    if (this.heading) this.heading.innerText = this.title;
    this.unload();
    this.play();
  },
  load: function(data, isVideo) {
    if (this.source) URL.revokeObjectURL(this.source);
    if (!data) return;
    this.source = URL.createObjectURL(data);
    this.audioOnly = !isVideo;
    this.unload();
    this.play();
  },
  unload: function() {
    if (this.video) {
      this.video.parentNode.removeChild(this.video);
      this.video = null;
    }
  },
  isReady: function() {
    return this.video && this.video.readyState === 4;
  },
  createMediaElement: function() {
    if (this.audioOnly && this.source) {
      let video = document.createElement('audio');
      video.src = '/stream/' + sender.source + sender.mime[0];
      video.type = sender.mime[1];
      return video;
    }
    
    let video = document.createElement('video');
    
    if (!this.source || this.source === '0') return video;
    if (typeof this.source === 'string' && this.source.indexOf('blob') === 0) {
      video.src = this.source;
    } else {
      video.innerHTML = '\
      <source src="/stream/' + this.source + '.webm" type="video/webm"></source>\
      <source src="/stream/' + this.source + this.mime[0] + '" type="' + this.mime[1] + '"></source>';
    }
    
    return video;
  },
  play: function() {
    if (!this.video) {
      this.video = readyVideo(this);
      this.player.media.appendChild(this.video);
      this.volume(this.video.volume, this.video.muted);
    }
    
    if (this.video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE) {
      this.video.load();
    }
    
    this.video.play();
  },
  pause: function() {
    if (this.video) this.video.pause();
    this.player.dataset.state = 'paused';
    this.suspend.style.display = 'none';
    return true;
  },
  error: function(e) {
    console.error(e);
    this.pause();
    if (errorPresent(this.video)) {
      const message = errorMessage(this.video);
      console.warn(message);
      this.player.dataset.state = 'error';
      this.player.error.message.innerText = message;
      if (!this.noise) this.noise = setupNoise(this.player.error);
    }
  },
  togglePlayback: function() {
    if (this.player.dataset.state == 'playing') return this.pause();
    this.play();
  },
  jump: function(progress) {
    const duration = parseFloat(this.video.duration) || 0;
    const time = duration * progress;
    this.video.currentTime = time;
    this.track(time, duration);
  },
  track: function(time, duration) {
    this.suspend.style.display = 'none';
    this.controls.repaintTrackBar((time / duration) * 100);
    if (this.noise) {
      this.noise.destroy();
      this.noise = null;
    }
  },
  volume: function(volume, muted) {
    if (this.video) this.video.volume = volume;
    this.controls.repaintVolumeSlider();
  }
};

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
  
  onFullscreenChange(() => {
    if (fullscreenPlayer) fullscreenPlayer.fullscreen(isFullscreen());
  });
});

export { Player };
