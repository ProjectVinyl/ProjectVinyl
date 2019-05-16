/*
 * Initialises basic video playback functionality.
 */
import { ajax } from '../../utils/ajax';
import { scrollTo } from '../../ui/scroll';
import { ContextMenu } from '../../ui/contextmenu';
import { Key } from '../../utils/misc';
import { errorMessage, errorPresent } from '../../utils/videos';
import { all } from '../../jslim/dom';
import { ready, bindAll, halt, bindEvent } from '../../jslim/events';
import { isFullscreen } from '../../utils/fullscreen';
import { cookies } from '../../utils/cookies';
import { TapToggler } from '../taptoggle';
import { fullscreenPlayer, setFullscreen } from './fullscreen';
import { PlayerControls } from './playercontrols';
import { setupNoise } from './noise';
import { attachMessageListener } from './itc';
import { resize } from './resize';
import { createVideoElement, addSource } from './video_element';
import { onPlaylistNavigate } from './playlist';
import { attachFloater } from './floatingplayer';

const speeds = [
  {name: '0.25x', value: 0.25},
  {name: '0.5x', value: 0.5},
  {name: 'Normal', value: 1},
  {name: '1.25x', value: 1.25},
  {name: '1.5x', value: 1.5},
  {name: 'Double', value: 2}
];

function registerEvents(player, el) {
  let tapped = false;
  let activeTouches = [];

  function onTouchEvent(ev) {
    activeTouches = activeTouches.filter(t => t.identifier !== ev.identifier)
  }

  bindAll(el, {
    click: ev => {
      if (ev.button !== 0) {
        return;
      }

      if (!player.contextmenu.hide(ev)) {
        let target = ev.target.closest('.items a, #playlist_next, #playlist_prev');
        if (target) {
          halt(ev);
          return player.navTo(target);
        }

        if (player.playlist && ev.target.closest('.playlist-toggle')) {
          return player.playlist.classList.toggle('visible');
        }
        
        if (ev.target.closest('.action')) {
          return;
        }

        if (player.player.dataset.state != 'playing' || player.dom.toggler.interactable()) {
          if (player.playlist && player.playlist.classList.contains('visible')) {
            return player.playlist.classList.remove('visible');
          }

          player.togglePlayback();
        }
      }
    },
    touchstart: ev => {
      if (fullscreenPlayer === player && activeTouches.length) {
        return halt(ev);
      }

      if (!tapped) {
        tapped = setTimeout(() => tapped = null, 500);
        activeTouches.push({identifier: ev.identifier});

        return;
      }
      
      clearTimeout(tapped);
      tapped = null;
      player.fullscreen(!isFullscreen());

      halt(ev);
    },
    touchmove: onTouchEvent,
    touchend: onTouchEvent,
    touchcancel: onTouchEvent
  });
    
  bindEvent(document, 'keydown', ev => {
    if (player.video && !document.querySelector('input:focus, textarea:focus')) {
      if (ev.keyCode === Key.SPACE) {
        player.togglePlayback();
        halt(ev);
      } else if (ev.keyCode == Key.LEFT) {
        player.skip(-3);
        halt(ev);
      } else if (ev.keyCode == Key.RIGHT) {
        player.skip(3);
        halt(ev);
      }
    }
  });
}

function playerElement(sender) {
  const player = sender.dom.querySelector('.player');
  player.media = player.querySelector('.playing');
  player.error = player.querySelector('.error');
  player.error.message = player.error.querySelector('.error-message');
  player.getPlayerObj = () => sender;
  
  return player;
}

function playerHeader(sender) {
  const heading = sender.dom.querySelector('h1 .title');
  if (heading) heading.addEventListener('mouseover', () => {
    if (sender.video && sender.video.currentTime) {
      heading.href = `/videos/${this.source}-${this.title}?resume=${this.video.currentTime}`;
    }
  });
  
  return heading;
}

export function Player() { }
Player.prototype = {
  constructor(el, standalone) {
    this.floater = document.querySelector('.floating-player');
    
    this.dom = el;
    this.embedded = !!el.dataset.embed;
    this.audioOnly = !!el.dataset.audio;
    this.source = el.dataset.video || el.dataset.audio;
    this.video = null;
    this.mime = (el.dataset.mime || '.mp4|video/m4v').split('|');
    this.time = parseInt(el.dataset.time || '0') || 0;
    this.title = el.dataset.title;
    
    this.suspend = el.querySelector('.suspend');
    this.player = playerElement(this);
    this.playlist = document.querySelector('.playlist');
    this.heading = playerHeader(this);
    this.controls = new PlayerControls(this, el.querySelector('.controls'));
    this.contextmenu = new ContextMenu(el.querySelector('.contextmenu'), this.dom, {
      'Loop': {
        initial: this.setLoop(false),
        callback: val => val(this.setLoop(!this.__loop))
      },
      'Speed': {
        initial: this.changeSpeed(2),
        callback: val => val(this.changeSpeed(this.__speed + 1))
      },
      'Play Automatically': {
        initial: this.setAutostart(!!cookies.get('autostart')),
        callback: val => val(this.setAutostart(!this.__autostart))
      },
      'Next Automatically': {
        initial: this.setAutoplay(!!cookies.get('autoplay')),
        display: el.dataset.autoplay == 'true',
        callback: val => val(this.setAutoplay(!this.__autoplay))
      }
    });
    
    attachMessageListener(this, !standalone);
    
    if (!el.dataset.pending) {
      attachFloater(this);
    }

    new TapToggler(this.dom);
    
    registerEvents(this, el);

    const selected = document.querySelector('.playlist a.selected');
    if (selected) {
      scrollTo(selected, document.querySelector('.playlist .scroll-container'));
    }

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
      onPlaylistNavigate(this, sender, json);
    });
  },
  fullscreen(on) {
    this.controls.fullscreen.innerHTML = `<i class="fa fa-${on ? 'restore' : 'arrows-alt'}"></i>`;
    this.player.media.style.cursor = on ? 'none' : '';
    
    if (fullscreenPlayer && fullscreenPlayer !== this) {
      fullscreenPlayer.fullscreen(false);
    }

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
    
    if (on) {
      this.dom.requestFullscreen();
    }

    setFullscreen(on ? this : null);
    return on;
  },
  maximise() {
    const holder = this.dom.closest('.slim');
    const state = holder.classList.contains('column-left');

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

    if (this.video) {
      this.video.playbackRate = speed.value;
    }

    return speed.name;
  },
  setAutoplay(on) {
    this.__autoplay = on;
    cookies.set('autoplay', on);

    if (on) {
      this.setLoop(false);
    }

    return on;
  },
  setAutostart(on) {
    this.__autostart = on;
    cookies.set('autoplay', on);

    return on;
  },
  setLoop(on) {
    this.__loop = on;

    if (this.video) {
      this.video.loop = on;
    }

    return on;
  },
  loadAttributesAndRestart(attr) {
    this.dom.style.backgroundImage = `url('/cover/${attr.source}.png')`;
    this.source = attr.source;
    this.mime = attr.mime;
    this.title = attr.title;
    this.audioOnly = attr.audioOnly;

    if (this.heading) {
      this.heading.innerText = this.title;
    }

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
      if (!this.audioOnly) {
        addSource(media, `/stream/${this.source}.webm`, 'video/webm');
      }
      addSource(media, `/stream/${this.source}${this.mime[0]}`, this.mime[1]);
    }
    
    return media;
  },
  play() {
    this.controls.play.innerHTML = `<i class="fa fa-pause"></i>`;
    
    if (!this.video) {
      this.video = createVideoElement(this);
      this.volume(this.video.volume, this.video.muted);
      this.video.load();
    }
    
    if (this.video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE) {
      this.video.load();
    }
    this.video.play();
  },
  pause() {
    this.controls.play.innerHTML = `<i class="fa fa-play"></i>`;
    
    if (this.video) {
      this.video.pause();
    }

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

      if (!this.noise) {
        this.noise = setupNoise(this.player.error);
      }
    }
  },
  togglePlayback() {
    if (this.player.dataset.state == 'playing') {
      return this.pause();
    }
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
    if (this.video) {
      this.video.volume = volume;
    }
    this.controls.repaintVolumeSlider(muted ? 0 : volume);
  }
};

ready(() => all('.video', v => {
  if (!v.dataset.pending && !v.classList.contains('unplayable')) {
    new Player().constructor(v);
  }
}));
