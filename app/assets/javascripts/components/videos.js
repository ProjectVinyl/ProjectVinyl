/*
 * Initialises basic video playback functionality.
 */
import { ajax } from '../utils/ajax';
import { scrollTo } from '../ui/scroll';
import { ContextMenu } from '../ui/contextmenu';
import { Key } from '../utils/misc';
import { errorMessage, errorPresent } from '../utils/videos';
import { all, each } from '../jslim/dom';
import { ready, bindAll, halt, bindEvent } from '../jslim/events';
import { isFullscreen, onFullscreenChange } from '../utils/fullscreen';
import { cookies } from '../utils/cookies';
import { TapToggler } from './taptoggle';
import { PlayerControls } from './playercontrols';
import { setupNoise } from './noise';

const speeds = [
  {name: '0.25x', value: 0.25},
  {name: '0.5x', value: 0.5},
  {name: 'Normal', value: 1},
  {name: '1.25x', value: 1.25},
  {name: '1.5x', value: 1.5},
  {name: 'Double', value: 2}
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
  if (!sender.__sendMessages) return;
  let id = parseInt(localStorage['::activeplayer'] || '0');
  sender.__seed = ((id + 1) % 3).toString();
  localStorage.setItem('::activeplayer', sender.__seed);
}

function attachMessageListener(sender) {
  bindEvent(window, 'storage', event => {
    if (event.key === '::activeplayer' && event.newValue !== sender.__seed) {
      sender.pause();
    }
  });
}

function readyVideo(sender) {
  let video = sender.createMediaElement();
  sender.player.media.appendChild(video);
  
  if (sender.time) {
    if (sender.isReady()) {
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
    if (!suspendTimer) suspendTimer = setTimeout(() => {
      suspendTimer = null;
      sender.suspend.classList.remove('hidden');
    }, 300);
  }
  
  bindAll(video, {
    abort: e => sender.error(e), error: e => sender.error(e),
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
    suspend: suspended, waiting: suspended, stalled: suspended,
    volumechange: () => {
      sender.volume(video.volume, video.muted || video.volume === 0);
    },
    seek: () => {
      sender.track(video.currentTime, sender.getDuration());
    },
    timeupdate: () => {
      if (suspendTimer) {
        clearTimeout(suspendTimer);
        suspendTimer = null;
      }
      sender.track(video.currentTime, sender.getDuration());
    },
    progress: () => {
      console.log('progress');
      sender.controls.repaintProgress(video);
    }
  });
  
  return video;
}

// Have to do this the long way to avoid caching errors in firefox
function addSource(video, src, type) {
  const source = document.createElement('SOURCE');
  source.type = type;
  source.src = src;
  video.appendChild(source);
}

export function Player() { }
Player.prototype = {
  // FIXME: way too much happening here
  constructor(el, standalone) {
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
    if (this.heading) this.heading.addEventListener('mouseover', () => {
      if (this.video && this.video.currentTime) {
        this.heading.href = `/videos/${this.source}-${this.title}?resume=${this.video.currentTime}`;
      }
    });
    
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
          if (target) {
            halt(ev);
            return this.navTo(target);
          }
          if (this.playlist && ev.target.closest('.playlist-toggle')) {
            return this.playlist.classList.toggle('visible');
          }
          
          if (ev.target.closest('.action')) return;
          if (this.player.dataset.state != 'playing' || this.dom.toggler.interactable()) {
            if (this.playlist && this.playlist.classList.contains('visible')) {
              return this.playlist.classList.remove('visible');
            }
            this.togglePlayback();
          }
        }
      },
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
      },
      touchmove: onTouchEvent,
      touchend: onTouchEvent,
      touchcancel: onTouchEvent
    });
    
    bindEvent(document, 'keydown', ev => {
      if (this.video && !document.querySelector('input:focus, textarea:focus')) {
        if (ev.keyCode === Key.SPACE) {
          this.togglePlayback();
          halt(ev);
        } else if (ev.keyCode == Key.LEFT) {
          this.skip(-3);
          halt(ev);
        } else if (ev.keyCode == Key.RIGHT) {
          this.skip(3);
          halt(ev);
        }
      }
    });
    
    this.contextmenu.addItem('Loop', this.setLoop(false), val => {
      val(this.setLoop(!this.__loop));
    });
    
    this.contextmenu.addItem('Speed', this.changeSpeed(2), val => {
      val(this.changeSpeed(this.__speed + 1));
    });
    
    if (el.dataset.autoplay == 'true') {
      this.contextmenu.addItem('Next Automatically', this.setAutoplay(!!cookies.get('autoplay')), val => {
        cookies.set('autoplay', val(this.setAutoplay(!this.__autoplay)));
      });
    }
    
    this.contextmenu.addItem('Play Automatically', this.setAutostart(!!cookies.get('autostart')), val => {
      cookies.set('autostart', val(this.setAutostart(!this.__autostart)));
    });
    
    const selected = document.querySelector('.playlist a.selected');
    if (selected) scrollTo(selected, document.querySelector('.playlist .scroll-container'));
    
    // at the bottom
    resize(el);
    
    if (!this.embedded) {
      if (el.dataset.resume === 'true' || this.__autostart || this.__autoplay) {
        this.play();
      }
    }
    
    return this;
  },
  navTo(sender) {
    ajax.get(`videos/${sender.dataset.videoId}.json`).json(json => {
      const next = document.querySelector('#playlist_next');
      const prev = document.querySelector('#playlist_prev');
      
      this.redirect = sender.href;
      this.loadAttributesAndRestart(json);
      
      var selected = document.querySelector('.playlist a.selected');
      if (selected) selected.classList.remove('selected');
      selected = document.querySelector(`.playlist a[data-id="${json.id}"]`);
      selected.classList.add('selected');
      scrollTo(selected, document.querySelector('.playlist .scroll-container'));
      
      if (next && json.next) {
        next.href = json.next.link;
        next.dataset.videoId = json.next.id;
      }
      if (prev && json.prev) {
        prev.href = json.prev.link;
        prev.dataset.videoId = json.prev.id;
      }
      
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
  fullscreen(on) {
    this.controls.fullscreen.innerHTML = `<i class="fa fa-${on ? 'restore' : 'arrows-alt'}"></i>`;
    this.player.media.style.cursor = on ? 'none' : '';
    
    if (fullscreenPlayer && fullscreenPlayer !== this) fullscreenPlayer.fullscreen(false);
    if (fullscreenPlayer && !on) {
      document.exitFullscreen();
      this.controls.dom.style.opacity = '';
      if (this.redirect) {
        if (this.video) {
          this.redirect += `${this.redirect.indexOf('?') >= 0 ? '&' : '?'}t=${this.video.currentTime}`;
        }
        document.location.replace(this.redirect);
      }
    }
    
    if (on) this.dom.requestFullscreen();
    setFullscreen(on ? this : null);
    return on;
  },
  maximise() {
    const holder = this.dom.closest('.slim');
    let state = holder.classList.contains('column-left');
    holder.classList.toggle('column-left', !state);
    holder.classList.toggle('full-width', state);
    if (state) {
      this.dom.dataset.height = this.dom.style.height;
    } else {
      this.dom.style.height = this.dom.dataset.height;
    }
    setTimeout(_ => resize(this.dom), 250);
  },
  changeSpeed(speed) {
    this.__speed = speed % speeds.length;
    speed = speeds[this.__speed];
    if (this.video) this.video.playbackRate = speed.value;
    return speed.name;
  },
  setAutoplay(on) {
    this.__autoplay = on;
    if (on) this.setLoop(false);
    return on;
  },
  setAutostart(on) {
    this.__autostart = on;
    return on;
  },
  setLoop(on) {
    this.__loop = on;
    if (this.video) this.video.loop = on;
    return on;
  },
  loadAttributesAndRestart(attr) {
    this.dom.style.backgroundImage = `url('/cover/${attr.source}.png')`;
    this.source = attr.source;
    this.mime = attr.mime;
    this.title = attr.title;
    this.audioOnly = attr.audioOnly;
    if (this.heading) this.heading.innerText = this.title;
    this.unload();
    this.play();
  },
  load(data, isVideo) {
    if (this.source) URL.revokeObjectURL(this.source);
    if (!data) return;
    this.source = URL.createObjectURL(data);
    this.audioOnly = !isVideo;
    this.unload();
    this.play();
  },
  unload() {
    if (this.video) {
      this.video.parentNode.removeChild(this.video);
      this.video = null;
    }
  },
  isReady() {
    return this.video && this.video.readyState === 4;
  },
  createMediaElement() {
    const media = document.createElement(this.audioOnly && this.source ? 'AUDIO' : 'VIDEO');
    
    if (!this.source || this.source === '0') return media;
    if (typeof this.source === 'string' && this.source.indexOf('blob') === 0) {
      media.src = this.source;
    } else {
      if (!this.audioOnly) addSource(media, `/stream/${this.source}.webm`, 'video/webm');
      addSource(media, `/stream/${this.source}${this.mime[0]}`, this.mime[1]);
    }
    
    return media;
  },
  play() {
    if (!this.video) {
      this.video = readyVideo(this);
      this.volume(this.video.volume, this.video.muted);
      this.video.load();
    }
    
    if (this.video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE) {
      this.video.load();
    }
    this.video.play();
  },
  pause() {
    if (this.video) this.video.pause();
    this.player.dataset.state = 'paused';
    this.suspend.classList.add('hidden');
    return true;
  },
  error(e) {
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
  togglePlayback() {
    if (this.player.dataset.state == 'playing') return this.pause();
    this.play();
  },
  getDuration() {
    return parseFloat(this.video.duration) || 0;
  },
  jump(progress) {
    const duration = this.getDuration();
    const time = duration * progress;
    this.video.currentTime = time;
    this.track(time, duration);
  },
  skip(increment) {
    this.video.currentTime += increment;
    this.track(this.video.currentTime, this.getDuration());
  },
  track(time, duration) {
    this.suspend.classList.add('hidden');
    this.controls.repaintTrackBar((time / duration) * 100);
    if (this.noise) {
      this.noise.destroy();
      this.noise = null;
    }
  },
  volume(volume, muted) {
    if (this.video) this.video.volume = volume;
    this.controls.repaintVolumeSlider(muted ? 0 : volume);
  }
};

function resize(obj) {
  applyResize(obj);
  
  setTimeout(() => applyResize(obj), 300);
}

function applyResize(obj) {
  const aspect = obj.dataset.aspect ? parseFloat(obj.dataset.aspect) : (16 / 9);
  obj.style.marginBottom = ''; // 16/9 aspect ratio
  obj.style.height = `${obj.clientWidth / aspect}px`;
}

bindEvent(window, 'resize', () => all('.video', resize));

onFullscreenChange(() => {
  if (fullscreenPlayer) fullscreenPlayer.fullscreen(isFullscreen());
});

ready(() => all('.video', v => {
  if (!v.dataset.pending && !v.classList.contains('unplayable')) (new Player()).constructor(v);
}));
