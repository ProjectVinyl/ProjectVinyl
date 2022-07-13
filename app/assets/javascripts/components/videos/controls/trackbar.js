import { addDelegatedEvent } from '../../../jslim/events';
import { toHMS } from '../../../utils/duration';
import { getPercentage } from '../../slider';
import { createMiniTile } from './minitile';

function didBufferChange(old, neu) {
  return !old
    || old.length != neu.length
    || (neu.length && (old.start != neu.start(0) || old.end != neu.end(neu.length - 1)));
}

function findChapter(chapters, time) {
  return (chapters || []).filter(chapter => chapter.time < time).reverse()[0] || {
    title: '',
    time: 0
  };
}

export function initTrackbar(player, dom) {
  let rangeEnd = 0;

  const track = dom.querySelector('.track');
  track.load = dom.querySelector('.track .load');
  track.chapters = dom.querySelector('.track .chapters');

  const preview = createMiniTile(player);
  preview.draw(0);

  const timer = {
    current: dom.querySelector('.timer .current'),
    total: dom.querySelector('.timer .total')
  };

  addDelegatedEvent(dom, 'slider:grab', '.track', ev => {
    if (!player.contextmenu.hide(ev)) {
      player.dom.classList.add('tracking');
    }
  });
  addDelegatedEvent(dom, 'slider:release', '.track', ev => {
    player.dom.classList.remove('tracking');
  });
  addDelegatedEvent(dom, 'slider:jump', '.track', ev => {
    if (!player.contextmenu.hide(ev)) {
      if (!player.video) player.play();
      drawPreview(ev.detail.data.x);
      player.jump(ev.detail.data.x);
    }
  });
  addDelegatedEvent(dom, 'mousemove', '.track', ev => {
    const progress = getPercentage(track, ev).x;
    drawPreview(progress);
    track.style.setProperty('--track-cursor', progress);
  });

  addDelegatedEvent(dom, 'focusin', '.track', ev => {
    drawPreview(player.getTime() / player.getDuration());
  });
  addDelegatedEvent(dom, 'keyup', 'li', ev => {
    if (ev.keyCode == 13 && !ev.target.closest('.track')) {
      ev.target.click();
    }
  });
  
  let buffer = [];
  let chapters = [];
  
  function drawPreview(progress) {
    const time = player.getDuration() * progress;

    preview.dom.style.left = (progress * 100) + '%';
    preview.dom.dataset.time = toHMS(time);
    preview.dom.dataset.chapterTitle = findChapter(player.params.chapters, time).title;
    preview.draw(time);
  }

  function updateBuffers(video) {
    const duration = player.getDuration();
    const videoBuffer = video.buffered;
    const result = [];

    for (let range = 0; range < videoBuffer.length; range++) {
      let start = videoBuffer.start(range) * 100 / duration;
      let end = videoBuffer.end(range) * 100 / duration;
      result.push(`<span style="left:${start}%;width:${end}%"></span>`);
    }

    track.load.innerHTML = result.join('');
    buffer = {
      length: videoBuffer.length,
      start: videoBuffer.length ? videoBuffer.start(0) : 0,
      end: videoBuffer.length ? videoBuffer.end(videoBuffer.length - 1) : 0
    };
  }

  return {
    seek(time) {
      const duration = player.getDuration();

      timer.current.innerText = toHMS(time);
      timer.total.innerText = toHMS(duration)
      track.style.setProperty('--track-progress', (time / duration) * 100);

      if (didBufferChange(buffer, player.video.buffered)) {
        updateBuffers(player.video);
      }

      if (player.params.chapters != chapters) {
        chapters = player.params.chapters;
        track.chapters.innerHTML = chapters.map((chapter, index) => {
          const start = chapter.time * 100 / duration;
          const end = index < (chapters.length - 1) ? (chapters[index + 1].time * 100 / duration) : 100;

          return `<span style="left:${start}%;width:${end - start}%"></span>`;
        }).join('');
      }
    },
    updateBuffers
  };
}