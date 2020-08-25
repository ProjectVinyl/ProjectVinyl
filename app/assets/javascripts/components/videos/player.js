/*
 * Initialises basic video playback functionality.
 */
import { ajax } from '../../utils/ajax';
import { scrollTo } from '../../ui/scroll';
import { ContextMenu } from '../../ui/contextmenu';
import { clamp } from '../../utils/math';
import { errorMessage, errorPresent } from '../../utils/videos';
import { all } from '../../jslim/dom';
import { ready, bindAll, bindEvent } from '../../jslim/events';
import { cookies } from '../../utils/cookies';
import { TapToggler } from '../taptoggle';
import { setFullscreen } from './fullscreen';
import { PlayerControls } from './playercontrols';
import { setupNoise } from './noise';
import { attachMessageListener } from './itc';
import { createVideoElement, addSource } from './video_element';
import { onPlaylistNavigate } from './playlist';
import { attachFloater } from './floatingplayer';
import { registerEvents } from './gestures';

const speeds = [
  {name: '0.25x', value: 0.25},
  {name: '0.5x', value: 0.5},
  {name: 'Normal', value: 1},
  {name: '1.25x', value: 1.25},
  {name: '1.5x', value: 1.5},
  {name: 'Double', value: 2}
];

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
      heading.href = `/videos/${sender.params.id}-${sender.params.title}?resume=${sender.video.currentTime}`;
    }
  });
  
  return heading;
}

function fillRequiredParams(params, el) {
  params.type = params.type || 'video';
  params.embedded = params.embedded || !!el.closest('.featured');
  params.mime = params.mime || ['.mp4', 'video/m4v'];
  params.time = params.time || 0;
  return params;
}

export function Player() { }
Player.prototype = {
  constructor(el, standalone) {
    this.floater = document.querySelector('.floating-player');
    
    this.params = fillRequiredParams(JSON.parse(unescape((el.dataset.source || '{}').replace('+', ' '))), el);
    delete el.dataset.source;

    this.dom = el;
    this.video = null;
    this.audioOnly = this.params.type === 'audio';
    this.volumeLevel = cookies.get('player_volume', 1);

    this.suspend = el.querySelector('.suspend');
    this.waterdrop = el.querySelector('.water-drop');
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
        display: this.params.autoplay,
        callback: val => val(this.setAutoplay(!this.__autoplay))
      }
    });
    
    attachMessageListener(this, !standalone);
    
    if (!el.dataset.pending && !this.params.embedded) {
      this.floater = attachFloater(this);
    }

    new TapToggler(this.dom);
    
    registerEvents(this, el);

    const selected = document.querySelector('.playlist a.selected');
    if (selected) {
      scrollTo(selected, document.querySelector('.playlist .scroll-container'));
    }

    if (!this.params.embedded) {
      if (this.params.resume || this.__autostart || this.__autoplay) {
        this.play();
      }
    }
    
    this.volume(this.volumeLevel, false);

    return this;
  },
  navTo(sender) {
    ajax.get(`videos/${sender.dataset.videoId}.json?list=${sender.dataset.albumId}`).json(json => {
      onPlaylistNavigate(this, sender, json);
    });
  },
  fullscreenChanged(inFullscreen) {
    if (!inFullscreen && this.redirect) {
      if (this.video) {
        this.redirect += `${this.redirect.indexOf('?') >= 0 ? '&' : '?'}t=${this.video.currentTime}`;
      }
      document.location.replace(this.redirect);
    }
  },
  fullscreen(on) {
    setFullscreen(on ? this : null);
    return on;
  },
  maximise() {
    const holder = this.dom.closest('.slim');
    const state = holder.classList.contains('column-left');

    holder.classList.toggle('column-left', !state);
    holder.classList.toggle('full-width', state);
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
    cookies.set('autostart', on);

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
    this.params = fillRequiredParams(attr, this.dom);

    this.dom.style.backgroundImage = `url('/stream/${attr.path}/${attr.id}/cover.png')`;
    this.source = null;
    this.audioOnly = this.params.type === 'audio';

    if (this.heading) {
      this.heading.innerText = this.params.title;
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
    const media = document.createElement(this.audioOnly ? 'AUDIO' : 'VIDEO');

    if (typeof this.source === 'string' && this.source.indexOf('blob') === 0) {
      media.src = this.source;
    } else {
      if (!this.audioOnly) {
        if (this.params.mime[0] != 'mp4') {
          addSource(media, `/stream/${this.params.path}/${this.params.id}/video.mp4`, 'video/mp4');
        }
        if (this.params.mime[0] != 'webm') {
          addSource(media, `/stream/${this.params.path}/${this.params.id}/video.webm`, 'video/webm');
        }
      } else if (this.params.mime[0] != 'mp3') {
        addSource(media, `/stream/${this.params.path}/${this.params.id}/audio.mp3`, 'audio/mp3');
      }
      addSource(media, `/stream/${this.params.path}/${this.params.id}/source${this.params.mime[0]}`, this.params.mime[1]);
    }
    
    return media;
  },
  getOrCreateVideo() {
    if (!this.video) {
      this.video = createVideoElement(this);
      this.volume(this.volumeLevel, !!this.isMuted);
      this.video.load();
    }
    return this.video;
  },
  play() {
    const video = this.getOrCreateVideo();

    if (video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE) {
      video.load();
    }
    video.play();

    if (this.dom.dataset.state !== 'paused') {
      ajax.put(`videos/${this.params.id}/play_count`).json(json => {
        all('.js-play-counter', counter => {
          counter.innerText = `${json.count} views`;
        });
      });
    }
  },
  pause() {
    if (this.video) {
      this.video.pause();
    }

    this.setState('paused');
    this.suspend.classList.add('hidden');
    return true;
  },
  error(e) {
    console.error(e);

    if (errorPresent(this.video)) {
      const message = errorMessage(this.video);
      console.warn(message);

      this.setState('error');
      this.player.error.message.innerText = message;
      this.suspend.classList.add('hidden');

      if (!this.noise) {
        this.noise = setupNoise(this.player.error);
      }
    } else {
      this.pause();
    }
  },
  setState(newState) {
    if (this.floater) {
      this.floater.dataset.state = newState;
    }
    this.dom.dataset.state = newState;
  },
  togglePlayback() {
    if (this.dom.dataset.state == 'playing') {
      return this.pause();
    }
    this.play();
  },
  getProgress() {
    return this.video ? this.video.currentTime / this.getDuration() : 0;
  },
  getDuration() {
    return this.video ? (parseFloat(this.video.duration) || 0) : this.params.duration;
  },
  getVolume() {
    return this.video.muted ? 0 : this.video.volume;
  },
  jump(progress) {
    const duration = this.getDuration();
    const time = duration * progress;

    this.video.currentTime = time;
    this.track(time, duration);
  },
  skip(time, volume) {
    if (this.video) {
      if (time) {
        this.video.currentTime += time;
        this.track(this.video.currentTime, this.getDuration());
        this.controls.track.touch();
      }
      if (volume) {
        this.volume(this.video.volume + volume, this.video.muted);
        this.controls.volume.slider.touch();
      }
    }
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
    volume = clamp(volume, 0, 1)
    if (this.video) {
      this.video.volume = volume;
      this.video.muted = muted;
    }
    this.volumeLevel = volume;
    this.isMuted = muted;
    cookies.set('player_volume', this.volumeLevel);
    this.controls.repaintVolumeSlider(muted ? 0 : volume);
  }
};

ready(() => all('.video', v => {
  if (!v.dataset.pending && !v.classList.contains('unplayable')) {
    new Player().constructor(v);
  }
}));
