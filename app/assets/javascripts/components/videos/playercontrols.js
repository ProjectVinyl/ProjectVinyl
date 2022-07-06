import { isFullscreen } from '../../utils/fullscreen';
import { addDelegatedEvent, bindEvent, halt } from '../../jslim/events';
import { TapToggler } from '../taptoggle';
import { toHMS } from '../../utils/duration';
import { Slider, SliderSensitive } from '../slider';
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

function findChapter(chapters, time) {
  return (chapters || []).filter(chapter => chapter.time < time).reverse()[0] || {
    title: '',
    time: 0
  };
}

function drawPreview(controls, progress) {
  const time = controls.player.getDuration() * progress;
  const chapter = findChapter(controls.player.params.chapters, time);

  controls.track.preview.style.left = (progress * 100) + '%';
  controls.track.preview.dataset.time = `${toHMS(time)}\n${chapter.title}`;
  controls.preview.draw(time);
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
  this.track.chapters = dom.querySelector('.track .chapters');
  this.track.fill = dom.querySelector('.track .fill');
  this.track.preview = dom.querySelector('.track .previewer');

  this.volume = dom.querySelector('.volume');
  this.volume.indicator = dom.querySelector('.volume .indicator i');
  this.volume.slider = dom.querySelector('.volume .slider');

  this.timer = {
    current: dom.querySelector('.timer .current'),
    total: dom.querySelector('.timer .total')
  };

  this.preview = createMiniTile(player);
  this.preview.draw(0);

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
  SliderSensitive(this.volume);
  SliderSensitive(player.dom);

  addDelegatedEvent(dom, 'mousemove', '.track', ev => {
    const progress = evToProgress(this.track, ev);
    drawPreview(this, progress);
    this.track.style.setProperty('--track-cursor', progress);
  });
  addDelegatedEvent(dom, 'focusin', '.track', ev => {
    drawPreview(this, player.getProgress());
  });
  addDelegatedEvent(dom, 'click', '.volume', ev => {
    if (ev.button !== 0) return;
    if (!player.contextmenu.hide(ev)) {
      if (this.volume.toggler.interactable()) {
        player.volume(player.volumeLevel, player.isMuted = !player.isMuted);
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
  addDelegatedEvent(dom, 'keyup', 'li', ev => {
    if (ev.keyCode == 13 && !ev.target.closest('.track')) {
      ev.target.click();
    }
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
    this.volume.style.setProperty('--volume-level', volume);
  },
  repaintTrackBar(percentFill) {
    const duration = this.player.getDuration();

    this.timer.current.innerText = toHMS(duration * percentFill / 100);
    this.timer.total.innerText = toHMS(duration)
    this.track.style.setProperty('--track-progress', percentFill);

    if (didBufferChange(this.buffer, this.player.video.buffered)) {
      this.repaintProgress(this.player.video);
    }

    if (this.player.params.chapters != this.chapters) {
      this.chapters = this.player.params.chapters;

      this.track.chapters.innerHTML = this.chapters.map((chapter, index) => {
        const start = chapter.time * 100 / duration;
        const end = index < (this.chapters.length - 1) ? (this.chapters[index + 1].time * 100 / duration) : 100;

        return `<span style="left:${start}%;width:${end - start}%"></span>`;
      }).join('');
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
