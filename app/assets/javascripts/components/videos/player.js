import { ajaxPut } from '../../utils/ajax';
import { scrollTo } from '../../ui/scroll';
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
import { initContextMenu } from './context_menu';
import { playerHeader, fillRequiredParams, readParams } from './parameters';
import { QueryParameters } from '../../queryparameters';

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
  this.contextMenuActions = initContextMenu(el.querySelector('.contextmenu'), this);

  attachMessageListener(this, !standalone);

  const navigation = document.getElementById('navigation');
  if (!this.dom.closest('.featured') && navigation && navigation.scrollIntoView) {
    navigation.scrollIntoView();
  }

  if (!el.dataset.pending) {
    this.dom.floater = attachFloater(this);
  }

  new TapToggler(this.dom);

  registerEvents(this, el);

  const selected = document.querySelector('.playlist a.selected');
  if (selected) {
    scrollTo(selected, document.querySelector('.playlist .scroll-container'));
  }

  if ((!this.params.embedded && this.__autostart) || QueryParameters.current.autoplay == '1') {
    this.play();
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
