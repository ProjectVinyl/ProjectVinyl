/*
 * Initialises basic video playback functionality.
 */
import { ajaxPut } from '../../utils/ajax';
import { scrollTo } from '../../ui/scroll';
import { ContextMenu } from '../../ui/contextmenu';
import { clamp } from '../../utils/math';
import { formatFuzzyBigNumber } from '../../utils/numbers';
import { ready } from '../../jslim/events';
import { cookies } from '../../utils/cookies';
import { TapToggler } from '../taptoggle';
import { setFullscreen } from './fullscreen';
import { PlayerControls } from './controls';
import { attachMessageListener } from './itc';
import { createVideoElement, addSource } from './video_element';
import { attachFloater } from './floatingplayer';
import { registerEvents } from './gestures';
import { playerHeader, fillRequiredParams, readParams } from './parameters';

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

export function Player(el, standalone) {
  this.params = readParams(el);

  this.dom = el;
  this.video = null;
  this.__audioOnly = this.params.type === 'audio';
  this.__volume = cookies.get('player_volume', 1);
  this.__currentTime = this.params.time || 0;

  this.dom.suspend = el.querySelector('.suspend');
  this.dom.player = playerElement(this);
  this.playlist = document.querySelector('.playlist');
  this.dom.heading = playerHeader(this);
  this.controls = new PlayerControls(this, el.querySelector('.controls'));

  this.contextMenuActions = {
    setAutostart: on => {
      this.__autostart = on;
      if (!this.nonpersistent) {
        cookies.set('autostart', on);
      }
      return on;
    },
    setAutoplay: on => {
      this.__autoplay = on;
      if (!this.nonpersistent) {
        cookies.set('autoplay', on);
      }
      if (on) {
        this.setLoop(false);
      }

      return on;
    },
    setLoop: on => {
      this.__loop = on;

      if (this.video) {
        this.video.loop = on;
      }

      return on;
    },
    setSpeed: speed => {
      this.__speed = speed % speeds.length;
      speed = speeds[this.__speed];

      if (this.video) {
        this.video.playbackRate = speed.value;
      }

      return speed.name;
    }
  };
  this.contextmenu = new ContextMenu(el.querySelector('.contextmenu'), this.dom, {
    'Loop': {
      initial: this.contextMenuActions.setLoop(false),
      callback: val => val(this.contextMenuActions.setLoop(!this.__loop))
    },
    'Speed': {
      initial: this.contextMenuActions.setSpeed(2),
      callback: val => val(this.contextMenuActions.setSpeed(this.__speed + 1))
    },
    'Play Automatically': {
      initial: this.contextMenuActions.setAutostart(!!cookies.get('autostart')),
      callback: val => val(this.contextMenuActions.setAutostart(!this.__autostart))
    },
    'Next Automatically': {
      initial: this.contextMenuActions.setAutoplay(!!cookies.get('autoplay')),
      display: this.params.autoplay,
      callback: val => val(this.contextMenuActions.setAutoplay(!this.__autoplay))
    }
  });

  attachMessageListener(this, !standalone);

  if (!el.dataset.pending) {
    this.dom.floater = attachFloater(this);
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

  this.volume(this.__volume, false);

  el.videoPlayer = this;
  return this;
}
Player.prototype = {
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
  loadAttributesAndRestart(attr) {
    this.params = fillRequiredParams(attr, this.dom);
    this.dom.style.backgroundImage = `url('/stream/${attr.path}/${attr.id}/cover.png')`;
    this.source = null;
    this.__audioOnly = this.params.type === 'audio';

    if (this.dom.heading) {
      this.dom.heading.innerText = this.params.title;
    }

    this.unload();
    this.play();
  },
  unload() {
    if (this.video) {
      this.video.remove();
      this.video = null;
    }
  },
  isReady() {
    return this.video && this.video.readyState === HTMLMediaElement.HAVE_ENOUGH_DATA;
  },
  createMediaElement() {
    const media = document.createElement(this.__audioOnly ? 'AUDIO' : 'VIDEO');

    if (typeof this.source === 'string' && this.source.indexOf('blob') === 0) {
      media.src = this.source;
    } else {
      if (!this.__audioOnly) {
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
  play() {
    if (!this.video) {
      this.video = createVideoElement(this);
      this.volume(this.__volume, !!this.__muted);
      this.skipTo(this.__currentTime);
      this.video.load();
    } else if (this.video.networkState === HTMLMediaElement.NETWORK_NO_SOURCE) {
      this.video.load();
    }

    this.video.play();

    if (!this.nonpersistent && this.dom.dataset.state !== 'paused') {
      ajaxPut(`videos/${this.params.id}/play_count`).json(json => {
        document.querySelectorAll('.js-play-counter').forEach(counter => {
          counter.innerText = `${formatFuzzyBigNumber(json.count)} views`;
        });
      });
    }
  },
  pause() {
    if (this.video) {
      this.video.pause();
    }

    this.setState('paused');
    this.dom.suspend.classList.add('hidden');
    return true;
  },
  togglePlayback() {
    if (this.dom.dataset.state == 'playing') {
      return this.pause();
    }
    this.play();
  },
  setState(newState) {
    if (this.dom.floater) {
      this.dom.floater.dataset.state = newState;
    }
    this.dom.dataset.state = newState;
  },
  getTime() {
    return this.video ? this.video.currentTime : this.__currentTime;
  },
  getDuration() {
    return this.video ? (parseFloat(this.video.duration) || this.params.duration) : this.params.duration;
  },
  isMuted() {
    return this.video ? this.video.muted : this.__muted;
  },
  getVolume() {
    return this.video ? this.video.volume : this.__volume;
  },
  jump(progress) {
    this.skipTo(this.getDuration() * progress);
  },
  skipTo(time) {
    if (this.video) {
      this.video.currentTime = time;
    }
    this.seek(time);
  },
  seek(time) {
    this.__currentTime = time;
    this.dom.suspend.classList.add('hidden');
    this.controls.trackbar.seek(time);
  },
  volume(volume, muted) {
    volume = clamp(volume, 0, 1)
    if (this.video) {
      this.video.volume = volume;
      this.video.muted = muted;
    }
    this.__volume = volume;
    this.__muted = muted;
    if (!this.nonpersistent) {
      cookies.set('player_volume', this.__volume);
    }
    this.controls.volumeSlider.repaint(muted ? 0 : volume);
  }
};

ready(() => document.querySelectorAll('.video:not([data-pending], .unplayable)').forEach(v => new Player(v)));
