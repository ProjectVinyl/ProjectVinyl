import { isFullscreen } from '../../utils/fullscreen';
import { addDelegatedEvent, bindEvent, halt } from '../../jslim/events';
import { TapToggler } from '../taptoggle';
import { toHMS } from '../../utils/duration';
import { Slider } from '../slider';
import { createMiniTile } from './minitile';
import { clampPercentage } from '../../utils/math';

function evToProgress(track, ev) {
  const width = track.clientWidth;
  if (width === 0) return -1;
  
  let x = ev.pageX;
  if (!x && ev.touches) {
    x = ev.touches[0].pageX || 0;
  }
  
  x -= track.getBoundingClientRect().left + window.pageXOffset;

  return clampPercentage(x, width);
}

function evToVolume(volume, ev) {
  const height = volume.slider.clientHeight;
  if (height === 0) return -1;
  
  let y = ev.pageY;
  if (!y && ev.touches) {
    y = ev.touches[0].pageY || 0;
  }
  
  y -= volume.slider.getBoundingClientRect().top + window.pageYOffset;

  return clampPercentage(height - y, height);
}

function didBufferChange(old, neu) {
  return !old
    || old.length != neu.length
    || (neu.length && old.start != neu.start(0) || old.end != neu.end(neu.length - 1));
}

function drawPreview(controls, progress) {
  if (!controls.player.video) {
    return;
  }

  const time = (parseInt(controls.player.video.duration) || 0) * progress;

  controls.track.preview.style.left = (progress * 100) + '%';
  controls.track.preview.dataset.time = toHMS(time);

  if (!controls.player.audioOnly) {
    controls.preview.draw(time);
  }
}

function getVolumeIcon(level) {
  if (level <= 0) return 'off';
  if (level < 0.33) return 'down';
  if (level < 0.66) return 'mid';
  return 'up';
}

export function PlayerControls(player, dom) {
  this.dom = dom;
  this.player = player;
  this.rangeEnd = 0;

  this.fullscreen = dom.querySelector('.fullscreen .indicator');
  this.play = dom.querySelector('.play .indicator');

  this.track = dom.querySelector('.track');
  this.track.bob = dom.querySelector('.track .bob');
  this.track.load = dom.querySelector('.track .load');
  this.track.fill = dom.querySelector('.track .fill');
  this.track.preview = dom.querySelector('.track .previewer');
  
  this.volume = dom.querySelector('.volume');
  this.volume.indicator = dom.querySelector('.volume .indicator i');
  this.volume.slider = dom.querySelector('.volume .slider');
  
  if (player.audioOnly) {
    this.preview = document.createElement('img');
    this.preview.src = `/stream/${player.params.path}/${player.params.id}/thumb.png`;
    this.track.preview.appendChild(this.preview);
  } else {
    this.preview = createMiniTile(player);
    this.track.preview.appendChild(this.preview.dom);
  }

  Slider(this.track, ev => {
    if (!player.contextmenu.hide(ev)) {
      if (!player.video) player.play();
      const progress = evToProgress(this.track, ev);
      if (ev.touches) {
        drawPreview(this, progress);
      }
      player.jump(progress);
    }
  }, (ev, next) => {
    if (!player.contextmenu.hide(ev)) {
      player.dom.classList.add('tracking');
      next(ev => {
        const progress = evToProgress(this.track, ev);
        drawPreview(this, progress);
        player.jump(progress);
      }, () => {
        requestAnimationFrame(() => player.dom.classList.remove('tracking'));
      });
    }
  });

  new TapToggler(this.volume);
  
  Slider(this.volume.slider, ev => {
    if (!player.contextmenu.hide(ev)) {
      const volume = evToVolume(this.volume, ev);
      if (volume >= 0) player.volume(volume);
    }
    halt(ev);
  }, (ev, next) => {
    if (!player.contextmenu.hide(ev)) {
      player.dom.classList.add('voluming');
      next(ev => {
        const volume = evToVolume(this.volume, ev);
        if (volume >= 0) player.volume(volume);
      }, () => {
        requestAnimationFrame(() => player.dom.classList.remove('voluming'));
      });
    }
    halt(ev);
  });

  addDelegatedEvent(dom, 'mousemove', '.track', ev => {
    drawPreview(this, evToProgress(this.track, ev));
  });
  addDelegatedEvent(dom, 'click', '.volume', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      if (this.volume.toggler.interactable()) {
        if (!player.video) player.play();
        player.volume(player.video.volume, player.video.muted = !player.video.muted);
      }
    }
  });
  addDelegatedEvent(dom, 'click', '.fullscreen', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      player.fullscreen(!isFullscreen());
      halt(ev);
    }
  });
  addDelegatedEvent(dom, 'click', '.maximise', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      player.maximise();
    }
  });
  addDelegatedEvent(dom, 'click', '.play', ev => {
    if (ev.button !== 0) return;
    player.togglePlayback();
  });
  bindEvent(dom, 'click', halt);
}
PlayerControls.prototype = {
  hide() {
    this.player.dom.dataset.hideControls = '1';
  },
  show() {
    this.player.dom.dataset.hideControls = '0';
  },
  repaintVolumeSlider(volume) {
    this.volume.indicator.setAttribute('class', 'fa fa-volume-' + getVolumeIcon(volume));
    volume *= 100;
    this.volume.slider.bob.style.bottom = volume + '%';
    this.volume.slider.fill.style.top = (100 - volume) + '%';
  },
  repaintTrackBar(percentFill) {
    this.track.bob.style.left = percentFill + '%';
    this.track.fill.style.right = (100 - percentFill) + '%';

    if (didBufferChange(this.buffer, this.player.video.buffered)) {
      this.repaintProgress(this.player.video);
    }
  },
  repaintProgress(video) {
    const duration = this.player.getDuration();
    const videoBuffer = video.buffered;
    const result = [];
    
    for (let range = 0; range < videoBuffer.length; range++) {
      let start = videoBuffer.start(range) * 100 / duration;
      let end = videoBuffer.end(range) * 100 / duration;
      result.push(`<span style="left:${start}%;width:${end}%"></span>`);
    }
    
    this.track.load.innerHTML = result.join('');
    this.buffer = {
      length: videoBuffer.length,
      start: videoBuffer.length ? videoBuffer.start(0) : 0,
      end: videoBuffer.length ? videoBuffer.end(videoBuffer.length - 1) : 0
    };
  }
};
