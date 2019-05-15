import { isFullscreen } from '../../utils/fullscreen';
import { addDelegatedEvent, halt } from '../../jslim/events';
import { TapToggler } from '../taptoggle';
import { toHMS } from '../../utils/duration';
import { Slider } from '../slider';
import { createMiniTile } from './minitile';

export function PlayerControls(player, dom) {
  this.dom = dom;
  this.player = player;
  this.rangeEnd = 0;
  
  this.track = dom.querySelector('.track');
  this.track.bob = dom.querySelector('.track .bob');
  this.track.load = dom.querySelector('.track .load');
  this.track.fill = dom.querySelector('.track .fill');
  this.track.preview = dom.querySelector('.track .previewer');
  
  if (player.audioOnly) {
    this.preview = document.createElement('img');
    this.preview.src = `/cover/${player.source}-small.png`;
    this.track.preview.appendChild(this.preview);
  } else {
    this.preview = createMiniTile(player);
    this.track.preview.appendChild(this.preview.dom);
  }
  
  Slider(this.track, ev => {
    if (!player.contextmenu.hide(ev)) {
      if (!player.video) player.play();
      const progress = this.evToProgress(ev);
      if (ev.touches) {
        this.drawPreview(progress);
      }
      player.jump(progress);
    }
  }, (ev, next) => {
    if (!player.contextmenu.hide(ev)) {
      player.dom.classList.add('tracking');
      next(ev => {
        const progress = this.evToProgress(ev);
        this.drawPreview(progress);
        player.jump(progress);
      }, () => {
        player.dom.classList.remove('tracking');
      });
    }
  });
  
  this.track.addEventListener('mousemove', ev => {
    this.drawPreview(this.evToProgress(ev));
  });
  
  this.volume = dom.querySelector('.volume');
  this.volume.indicator = dom.querySelector('.volume .indicator i');
  this.volume.slider = dom.querySelector('.volume .slider');
  this.volume.addEventListener('click', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      if (this.volume.toggler.interactable()) {
        if (!player.video) player.play();
        player.volume(player.video.volume, player.video.muted = !player.video.muted);
      }
    }
  });
  
  new TapToggler(this.volume);
  
  Slider(this.volume.slider, ev => {
    if (!player.contextmenu.hide(ev)) {
      const volume = this.evToVolume(ev);
      if (volume >= 0) player.volume(volume);
    }
    halt(ev);
  }, (ev, next) => {
    if (!player.contextmenu.hide(ev)) {
      player.dom.classList.add('voluming');
      next(ev => {
        const volume = this.evToVolume(ev);
        if (volume >= 0) player.volume(volume);
      }, () => {
        player.dom.classList.remove('voluming');
      });
    }
    halt(ev);
  });
  
  this.fullscreen = dom.querySelector('.fullscreen .indicator');
  dom.querySelector('.fullscreen').addEventListener('click', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      player.fullscreen(!isFullscreen());
      halt(ev);
    }
  });
  
  dom.querySelector('.maximise').addEventListener('click', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      player.maximise();
      halt(ev);
    }
  })
  
  addDelegatedEvent(dom, 'click', 'li', halt);
}
PlayerControls.prototype = {
  hide() {
    this.dom.style.opacity = 0;
    this.player.player.querySelector('.playing').style.cursor = 'none';
  },
  show() {
    this.dom.style.opacity = 1;
    this.player.player.querySelector('.playing').style.cursor = '';
  },
  evToProgress(ev) {
    const width = this.track.clientWidth;
    if (width === 0) return -1;
    
    let x = ev.pageX;
    if (!x && ev.touches) {
      x = ev.touches[0].pageX || 0;
    }
    
    x -= this.track.getBoundingClientRect().left + window.pageXOffset;
    return clampPercentage(x, width);
  },
  evToVolume(ev) {
    const height = this.volume.slider.clientHeight;
    if (height === 0) return -1;
    
    let y = ev.pageY;
    if (!y && ev.touches) {
      y = ev.touches[0].pageY || 0;
    }
    
    y -= this.volume.slider.getBoundingClientRect().top + window.pageYOffset;
    return clampPercentage(height - y, height);
  },
  drawPreview(progress) {
    if (!this.player.video) return;
    this.track.preview.style.left = (progress * 100) + '%';
    const time = (parseInt(this.player.video.duration) || 0) * progress;
    this.track.preview.dataset.time = toHMS(time);
    if (!this.player.audioOnly) this.preview.draw(time);
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

function didBufferChange(old, neu) {
  return !old || old.length != neu.length || (neu.length && old.start != neu.start(0) || old.end != neu.end(neu.length - 1));
}

function getVolumeIcon(level) {
  if (level <= 0) return 'off';
  if (level < 0.33) return 'down';
  if (level < 0.66) return 'mid';
  return 'up';
}

function clampPercentage(p, max) {
  if (p < 0) return 0;
  if (p > max) return 1;
  return p / max;
}
