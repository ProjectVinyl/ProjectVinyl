/*
Initialises basic video playback funtionality.

Copyright Project Vinyl Foundation 2016
*/

function Player() {}
(function() {
  const Key = { SPACE: 32 };
  /* Standardise fullscreen API */
  (function(p) {
    Player.requestFullscreen = p.requestFullscreen || p.mozRequestFullScreen || p.msRequestFullscreen || p.webkitRequestFullscreen || function() {};
    Player.exitFullscreen = document.exitFullscreen || document.mozCancelFullScreen || document.msExitFullscreen || document.webkitExitFullscreen || function() {};
    Player.isFullscreen = function() {
      return document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
    };
  }(Element.prototype));
  Player.onFullscreen = function(func) {
    $(document).on('webkitfullscreenchange mozfullscreenchange fullscreenchange', func);
  };
  const VIDEO_ELEMENT = document.createElement('video');
  Player.canPlayType = function(mime) {
    return Boolean((mime = VIDEO_ELEMENT.canPlayType(mime)).length) && mime !== 'no';
  };
  Player.speeds = [
    {name: 'Double', value: 2},
    {name: '1.5x', value: 1.5},
    {name: '1.25x', value: 1.25},
    {name: 'Normal', value: 1},
    {name: '0.5x', value: 0.5},
    {name: '0.25x', value: 0.25}
  ];
  Player.createVideoElement = function(player) {
    if (!player.source || player.source == '0') return $('<video></video>');
    if (typeof player.source === 'string' && player.source.indexOf('blob') == 0) return $(`<video src="${player.source}"></video>`);
    return $(`\
            <video>\
             <source src="/stream/${player.source}.webm" type="video/webm"></source>\
             <source src="/stream/${player.source}${player.mime[0]}" type="${player.mime[1]}"></source>\
            </video>`);
  };
  Player.errorMessage = function(video) {
    if (!video.error) {
      switch (video.networkState) {
        case HTMLMediaElement.NETWORK_NO_SOURCE:
          return 'Network Error';
      }
      return 'Unknown Error';
    }
    switch (video.error.code) {
      case video.error.MEDIA_ERR_ABORTED: return 'Playback Aborted';
      case video.error.MEDIA_ERR_NETWORK: return 'Network Error';
      case video.error.MEDIA_ERR_DECODE: return 'Feature not Supported';
      case video.error.MEDIA_ERR_SRC_NOT_SUPPORTED: return 'Codec not supported';
      default: return 'Unknown Error';
    }
  };
  Player.errorPresent = function(video) {
    return (video.error && video.error.code != video.error.MEDIA_ERR_ABORTED) || (video.networkState == HTMLMediaElement.NETWORK_NO_SOURCE);
  };
  Player.isready = function(video) {
    return video.readyState == 4;
  };
  Player.noise = (function() {
    let canvas = null, ctx = null;
    let toggle = true;
    function noise(ctx) {
      let w = ctx.canvas.width,
          h = ctx.canvas.height,
          idata = ctx.createImageData(w, h),
          buffer32 = new Uint32Array(idata.data.buffer),
          len = buffer32.length,
          i = 0;
      for (; i < len;) buffer32[i++] = ((255 * Math.random()) | 0) << 24;
      ctx.putImageData(idata, 0, 0);
    }
    function loop() {
      toggle = !toggle;
      if (toggle) return requestAnimationFrame(loop);
      noise(ctx);
      requestAnimationFrame(loop);
    }
    return function setupNoise() {
      if (canvas !== null) return canvas;
      canvas = document.createElement('canvas');
      ctx = canvas.getContext('2d');
      canvas.width = canvas.height = 256;
      loop();
      return canvas;
    };
  }());
  Player.generate = function(holder) {
    holder.prepend('<div class="player" >\
    <span class="playing"></span>\
    <span class="error"><span class="error-message"></span></span>\
    <span class="suspend" style="display:none"><i class="fa fa-pulse fa-spinner"></i></span>\
    <span class="pause resize-holder">\
      <span class="playback"></span>\
      <h1 class="resize-target" style="display:none;"><a class="title"></a></h1>\
    </span>\
  </div>\
  <div class="controls playback-controls">\
    <ul>\
      <li class="track">\
        <span class="fill"></span>\
        <div class="previewer"></div>\
        <span class="bob"></span>\
      </li>\
      <li class="icon volume">\
        <span class="indicator"><i class="fa fa-volume-up"></i></span>\
        <div class="slider">\
          <span class="fill"></span>\
          <span class="bob"></span>\
        </div>\
      </li>\
      <li class="icon fullscreen">\
        <span class="indicator"><i class="fa fa-arrows-alt"></i></span>\
      </li>\
    </ul>\
  </div>\
  <ul class="contextmenu"></ul>');
  };
  let fadeControl = null;
  function controlsFade() {
    if (Player.fullscreenPlayer) {
      Player.fullscreenPlayer.controls.css('opacity', 0);
      Player.fullscreenPlayer.player.find('.playing').css('cursor', 'none');
    }
    fadeControl = null;
  }
  function attachMessageListener(me) {
    $(window).on('storage', ev => {
      if (ev.originalEvent.key === '::activeplayer' && ev.originalEvent.newValue != me.__seed) {
        me.pause();
      }
    });
  }
  function sendMessage(me) {
    if (me.__sendMessages) {
      me.__seed = String((parseInt(localStorage['::activeplayer'] || '0') + 1) % 3);
      localStorage.setItem('::activeplayer', me.__seed);
    }
  }
  Player.onFullscreen(() => {
    if (Player.fullscreenPlayer) {
      Player.fullscreenPlayer.fullscreen(Player.isFullscreen());
    }
  });
  function canGen(childs) {
    return !childs.length || (childs.length == 1 && childs.first().hasClass('playlist'));
  }
  Player.Extend = function(Child, overrides) {
    Child.prototype = new this();
    Child.Super = this.prototype;
    Child.Extend = this.Extend;
    const keys = Object.keys(overrides);
    for (let i = keys.length; i--;) {
      Child.prototype[keys[i]] = overrides[keys[i]];
    }
  };
  Player.prototype = {
    constructor(el, standalone) {
      if (canGen(el.children())) Player.generate(el);
      const me = this;
      this.__sendMessages = !standalone;
      this.dom = el;
      this.player = el.find('.player');
      this.player.error = this.player.find('.error');
      this.player.error.message = this.player.error.find('.error-message');
      this.suspend = el.find('.suspend');
      this.contextmenu = el.find('.contextmenu');
      this.contextmenu.unset = 1;
      this.player[0].getPlayerObj = function() {
        return me;
      };
      this.video = null;
      this.mime = (el.attr('data-mime') || '.mp4|video/m4v').split('|');
      this.controls = el.find('.controls');
      this.source = el.attr('data-video');
      if (!this.source) {
        this.source = el.attr('data-audio');
        this.audioOnly = true;
        this.preview = $(`<img src="/cover/${this.source}-small.png" />`)[0];
      } else {
        this.preview = $('<canvas />')[0];
      }

      this.time = el.attr('data-time');

      resize.apply(el);

      el.find('h1 .title').text(this.title = el.attr('data-title'));
      if (this.artist = el.attr('data-artist')) el.find('h1 .artist').text(this.artist);

      new TapToggler(this.dom);
      el.on('click', ev => {
        if (!me.removeContext(ev)) {
          if (!me.player.hasClass('playing') || me.dom.toggler.interactable()) {
            if (me.dom.playlist && me.dom.playlist.hasClass('visible')) {
              me.dom.playlist.toggleClass('visible');
            } else {
              me.toggleVideo();
            }
          }
        }
      });
      el.on('contextmenu', ev => {
        me.showContext(ev);
      });
      const active_touches = [];
      let tapped = false;
      el.on('touchstart', function(ev) {
        if (Player.fullscreenPlayer == this) {
          if (active_touches.length > 0) {
            me.halt(ev);
            return;
          }
        }
        if (tapped) {
          me.fullscreen(!Player.isFullscreen());
          me.halt(ev);
          clearTimeout(tapped);
          tapped = null;
          return;
        } else {
          tapped = setTimeout(() => {
            tapped = null;
          }, 500);
        }
        me.dom.toggler.update(ev);
        active_touches.push({identifier: ev.identifier});
      });
      el.on('touchmove touchend touchcancel', ev => {
        for (let i = 0; i < active_touches; i++) {
          if (active_touches[i].identifier == ev.identifier) {
            active_touches.splice(i, 1);
          }
        }
      });
      this.__loop = false;
      this.__speed = 3;
      this.contextmenu.on('click', this.halt);
      this.addContext('Loop', false, val => {
        val(me.loop(!me.__loop));
      });
      this.addContext('Speed', me.speed(me.__speed), val => {
        me.__speed = (me.__speed + 1) % Player.speeds.length;
        val(me.speed(me.__speed));
      });

      $(document).on('click', ev => {
        me.removeContext(ev);
      });
      $(document).on('keydown', ev => {
        if (ev.which == Key.SPACE) {
          if (!$('input:focus,textarea:focus').length) {
            if (me.video) {
              me.toggleVideo();
              me.halt(ev);
            }
          }
        }
      });
      if (this.controls.length) {
        this.controls.track = this.controls.find('.track');
        this.controls.track.on('mousedown', ev => {
          if (!me.removeContext(ev)) {
            me.checkstart();
            me.jump(ev);
          }
        });
        this.controls.track.bob = this.controls.find('.track .bob');
        this.controls.track.fill = this.controls.find('.track .fill');
        this.controls.track.bob.on('mousedown', ev => {
          if (!me.removeContext(ev)) me.startChange(ev);
        });
        this.controls.track.bob.on('touchstart', ev => {
          me.removeContext(ev);
          me.startChange(ev);
        });
        this.controls.track.preview = el.find('.track .previewer');
        this.controls.track.preview.append(this.preview);
        this.controls.track.on('mousemove', ev => {
          me.drawPreview(me.evToProgress(ev));
        });
        this.controls.volume = this.controls.find('.volume');
        this.controls.volume.on('click', ev => {
          if (!me.removeContext(ev)) {
            if (me.controls.volume.toggler.interactable()) {
              me.muteUnmute();
            }
          }
        });
        new TapToggler(this.controls.volume);
        this.controls.volume.on('touchstart', ev => {
          me.controls.volume.toggler.update(ev);
          me.halt(ev);
        });

        this.controls.volume.bob = this.controls.find('.volume .bob');
        this.controls.volume.fill = this.controls.find('.volume .fill');
        this.controls.volume.bob.on('mousedown', ev => {
          if (!me.removeContext(ev)) me.startChangeVolume(ev);
        });
        this.controls.volume.bob.on('touchstart', ev => {
          me.removeContext(ev);
          me.startChangeVolume(ev);
        });
        this.controls.volume.slider = this.controls.find('.volume .slider');
        this.controls.volume.slider.on('mousedown', ev => {
          if (!me.removeContext(ev)) {
            me.checkstart();
            me.changeVolume(ev);
          }
        });
        this.controls.fullscreen = this.controls.find('.fullscreen .indicator');
        this.controls.find('.fullscreen').on('click', ev => {
          if (!me.removeContext(ev)) {
            me.fullscreen(!Player.isFullscreen());
            me.halt(ev);
          }
        });
        this.controls.volume.slider.on('click', this.halt);
        this.controls.find('li').on('click', this.halt);
      }
      attachMessageListener(this);
      if (el.attr('data-autoplay')) {
        this.checkstart();
        this.addContext('Autoplay', this.autoplay(!document.cookie.replace(/(?:(?:^|.*;\s*)autoplay\s*\=\s*([^;]*).*$)|^.*$/, '$1')), val => {
          val(me.__autoplay = !me.__autoplay);
          document.cookie = `autoplay=${on ? ';' : '1;'}`;
        });
      } else if (el.attr('data-resume') == 'true') {
        this.checkstart();
      }
      return this;
    },
    removeContext(ev) {
      if (ev.which == 1 && this.contextmenu.css('display') == 'table') {
        this.contextmenu.css('opacity', '');
        const me = this;
        setTimeout(() => {
          me.contextmenu.css('display', '');
        }, 100);
        return 1;
      }
      return 0;
    },
    showContext(ev) {
      let y = ev.pageY;
      let x = ev.pageX;
      if (x + this.contextmenu.width() > $(window).width()) x = $(window).width() - this.contextmenu.width();
      if (y + this.contextmenu.height() + 10 >= $(window).height()) y = $(window).height() - this.contextmenu.height() - 10;
      this.contextmenu.css({
        top: y - this.dom.offset().top,
        left: x - this.dom.offset().left,
        display: 'table'
      });
      this.contextmenu.css('opacity', '1');
      this.halt(ev);
    },
    setEmbed(id) {
      this.player.find('.pause h1').css({
        'pointer-events': 'initial', display: ''
      });
      const link = this.player.find('.pause h1 a');
      link.attr({
        target: '_blank', href: `/view/${id}-${this.title}`
      });
      const me = this;
      link.on('mouseover', () => {
        if (me.video && me.video.currentTime > 0) {
          link.attr('href', `/view/${id}-${me.title}?resume=${me.video.currentTime}`);
        }
      });
      link.on('click', ev => {
        ev.stopPropagation();
      });
    },
    setPlaylist(album_id, album_index) {
      this.album = {
        id: album_id, index: album_index
      };
      this.dom.playlist = $('.playlist');
      this.dom.playlist.link = $('<div class="playlist-toggle"><i class="fa fa-list" /></div>');
      this.dom.append(this.dom.playlist.link);
      const me = this;
      this.dom.playlist.link.on('click', ev => {
        me.dom.playlist.toggleClass('visible');
        me.halt(ev);
      });
      this.addContext('Autoplay', this.autoplay(!document.cookie.replace(/(?:(?:^|.*;\s*)autoplay\s*\=\s*([^;]*).*$)|^.*$/, '$1')), val => {
        val(me.__autoplay = !me.__autoplay);
        document.cookie = `autoplay=${on ? ';' : '1;'}`;
      });
      this.dom.playlist.on('click', '.items a, #playlist_next, #playlist_prev', function(ev) {
        const next = $(this);
        ajax.get(`view${next.attr('href')}`, json => {
          me.redirect = next.attr('href');
          me.loadAttributesAndRestart(json);
          if (json.next) {
            $('#playlist_next').attr('href', json.next);
          }
          if (json.prev) {
            $('#playlist_prev').attr('href', json.prev);
          }
          $('.playlist a.selected').removeClass('selected');
          const selected = $(`.playlist a[data-id=${json.id}]`);
          selected.addClass('selected');
          scrollTo(selected, '.playlist .scroll-container');
        });
        me.halt(ev);
      });
    },
    addContext(title, initial, callback) {
      const item = $(`<li><div class="label">${title}</div></li>`);
      const value = $('<div class="value" ></div>');
      item.append(value);
      function val(s) {
        value.html(typeof s === 'boolean' ? s ? '<i class="fa fa-check" />' : '' : s);
      }
      val(initial);
      item.on('click', () => {
        callback(val);
      });
      this.contextmenu.append(item);
    },
    speed(speed) {
      speed = Player.speeds[speed] || Player.speeds[3];
      if (this.video) this.video.playbackRate = speed.value;
      return speed.name;
    },
    fullscreen(on) {
      this.onfullscreen(on);
      if (!Player.requestFullscreen) return false;
      if (fadeControl != null) clearTimeout(fadeControl);
      if (Player.fullscreenPlayer && Player.fullscreenPlayer != this) {
        Player.fullscreenPlayer.fullscreen(false);
      }
      if (on) {
        Player.requestFullscreen.apply(this.dom[0]);
        Player.fullscreenPlayer = this;
        fadeControl = setTimeout(controlsFade, 1000);
      } else if (Player.fullscreenPlayer) {
        if (this.redirect) {
          if (this.video) {
            this.redirect += `${this.redirect.indexOf('?') >= 0 ? '&' : '?'}t=${this.video.currentTime}`;
          }
          document.location.replace(this.redirect);
          return;
        }
        Player.fullscreenPlayer = null;
        Player.exitFullscreen.apply(document);
        this.controls.css('opacity', '');
      }
      Player.fullscreenPlayer = on ? this : null;
      return on;
    },
    onfullscreen(on) {
      this.controls.fullscreen.html(on ? '<i class="fa fa-restore"></i>' : '<i class="fa fa-arrows-alt"></i>');
      if (!on) this.player.find('.playing').css('cursor', '');
    },
    autoplay(on) {
      this.__autoplay = on;
      if (on) {
        this.loop(false);
      }
      return on;
    },
    loop(on) {
      this.__loop = on;
      if (this.video) this.video.loop = on;
      return on;
    },
    checkstart() {
      if (!this.video) this.start();
    },
    loadAttributesAndRestart(attr) {
      this.dom.css('background-image', `url('/cover/${attr.source}.png')`);
      this.dom.find('h1 .title').text(this.title = attr.title);
      this.dom.find('h1 .artist').text(this.artist = attr.artist);
      this.source = attr.source;
      this.mime = attr.mime;
      this.audioOnly = attr.audioOnly;
      if (this.video) {
        $(this.video).remove();
        this.video = null;
      }
      this.start();
    },
    load(data) {
      this.audioOnly = false;
      if (this.source) {
        URL.revokeObjectURL(this.source);
      }
      if (data) {
        this.source = URL.createObjectURL(data);
        if (this.audioOnly) {
          this.video = null;
          this.start();
        } else {
          this.video.src = this.source;
        }
        this.video.load();
      }
    },
    loadURL(url) {
      this.audioOnly = false;
      if (this.source) {
        URL.revokeObjectURL(this.source);
      }
      if (url) {
        this.source = url;
        if (this.audioOnly) {
          this.video = null;
          this.start();
        } else {
          if (!this.video) this.start();
          this.video.src = this.source;
        }
        this.video.load();
      }
    },
    start() {
      if (!this.video) {
        let video;
        if (this.audioOnly && this.source) {
          video = $(`<audio src="/stream/${this.source}${this.mime[0]}" type="${this.mime[1]}"></audio>`);
        } else {
          video = Player.createVideoElement(this);
        }
        this.video = video[0];
        if (this.time && this.time != '0') {
          if (Player.isready(this.video)) {
            this.video.currentTime = parseInt(this.time);
          } else {
            const t = parseInt(this.time);
            this.video.addEventListener('canplay', function set_time() {
              this.currentTime = t;
              this.removeEventListener('canplay', set_time);
            });
          }
        }
        this.player.find('.playing').append(this.video);
        const me = this;
        video.on('pause', () => {
          me.pause();
        });
        video.on('play', function() {
          me.player.addClass('playing');
          me.player.removeClass('stopped');
          me.player.removeClass('paused');
          me.player.removeClass('error');
          me.video.loop = Boolean(me.__loop);
          sendMessage(me);
          me.volume(this.volume, this.muted);
        });
        video.on('abort error', e => {
          me.error(e);
        });
        video.find('source').last().on('error', e => {
          me.error(e);
        });
        video.on('ended', () => {
          if (me.__autoplay) {
            const next = $('#playlist_next');
            if (next.length) {
              if (Player.fullscreenPlayer == me || me.album) {
                ajax.get(`view${next.attr('href')}`, json => {
                  me.redirect = next.attr('href');
                  me.loadAttributesAndRestart(json);
                  if (json.next) {
                    next.attr('href', json.next);
                  } else {
                    next.remove();
                    $('.buff-right').removeClass('.buff-right');
                  }
                  if (json.prev) {
                    $('#playlist_prev').attr('href', json.prev);
                  } else {
                    $('#playlist_prev').remove();
                  }
                  $('.playlist a.selected').removeClass('selected');
                  const selected = $(`.playlist a[data-id=${json.id}]`);
                  selected.addClass('selected');
                  scrollTo(selected, '.playlist .scroll-container');
                });
              } else {
                document.location.replace(next.attr('href'));
              }
            }
          } else {
            if (me.pause()) me.player.addClass('stopped');
          }
        });
        let suspendTimer = null;
        video.on('suspend waiting', () => {
          if (!suspendTimer) {
            suspendTimer = setTimeout(() => {
              me.suspend.css('display', 'block');
            }, 3000);
          }
        });
        video.on('volumechange', () => {
          me.volume(me.video.volume, me.video.muted || me.video.volume == 0);
        });
        video.on('timeupdate', () => {
          if (suspendTimer) {
            clearTimeout(suspendTimer);
            suspendTimer = null;
          }
          me.track(me.video.currentTime, parseInt(me.video.duration) || 0);
        });
        this.volume(me.video.volume, video.muted);
      }
      if (this.video.networkState == HTMLMediaElement.NETWORK_NO_SOURCE) {
        this.video.load();
      }
      this.video.play();
    },
    stop() {
      this.pause();
      this.changetrack(0);
      this.video.parentNode.removeChild(this.video);
      this.video = null;
      this.suspend.css('display', 'none');
    },
    pause() {
      this.player.removeClass('playing');
      this.player.addClass('paused');
      if (this.video) this.video.pause();
      this.suspend.css('display', 'none');
      return true;
    },
    error(e) {
      this.pause();
      if (Player.errorPresent(this.video)) {
        const message = Player.errorMessage(this.video);
        this.player.addClass('stopped');
        this.player.addClass('error');
        this.player.error.message.text(message);
        if (!this.noise) {
          this.noise = Player.noise();
          this.player.error.append(this.noise);
        }
        console.warn(message);
      }
      console.log(e);
    },
    toggleVideo() {
      if (!this.player.hasClass('playing')) {
        this.start();
      } else {
        this.pause();
      }
    },
    track(time, duration) {
      const percentFill = (time / duration) * 100;
      this.controls.track.bob.css('left', `${percentFill}%`);
      this.controls.track.fill.css('right', `${100 - percentFill}%`);
      if (this.dom.toggler.touching()) {
        this.controls.track.preview.css('left', `${percentFill}%`);
        this.controls.track.preview.attr('data-time', this.descriptive(time));
      }
      this.suspend.css('display', 'none');
    },
    changetrack(progress) {
      if (progress < 0) progress = 0;
      if (progress > 1) progress = 1;
      const duration = parseFloat(this.video.duration) || 0;
      const time = duration * progress;
      this.video.currentTime = time;
      this.track(time, duration);
    },
    jump(ev) {
      const progress = this.evToProgress(ev);
      this.changetrack(progress);
      if (ev.originalEvent.touches) {
        this.drawPreview(progress);
      }
      this.halt(ev);
    },
    evToProgress(ev) {
      let x = ev.pageX;
      if (!x && ev.originalEvent.touches) {
        x = ev.originalEvent.touches[0].pageX || 0;
      }

      x -= this.controls.track.offset().left;
      if (x < 0) x = 0;
      if (x > this.controls.track.width()) x = this.controls.track.width();
      return x / this.controls.track.width();
    },
    startChange(ev, bob) {
      this.checkstart();
      const me = this;
      const func = function(ev) {
        me.jump(ev);
      };
      this.dom.addClass('tracking');
      $(document).on('mousemove touchmove', func);
      const ender = function() {
        $(document).off('mouseup touchend touchcancel', ender);
        $(document).off('mousemove touchmove', func);
        me.dom.removeClass('tracking');
      };
      $(document).one('mouseup touchend touchcancel', ender);
      this.halt(ev);
    },
    startChangeVolume(ev) {
      this.checkstart();
      const me = this;
      const func = function(ev) {
        me.changeVolume(ev);
      };
      this.dom.addClass('voluming');
      $(document).on('mousemove touchmove', func);
      const ender = function() {
        $(document).off('mouseup touchend touchcancel', ender);
        $(document).off('mousemove touchmove', func);
        me.dom.removeClass('voluming');
      };
      $(document).one('mouseup touchend touchcancel', ender);
      this.halt(ev);
    },
    changeVolume(ev) {
      const height = this.controls.volume.slider.height();
      if (height == 0) return;
      let y = ev.pageY;
      if (!y && ev.originalEvent.touches) {
        y = ev.originalEvent.touches[0].pageY || 0;
      }
      y -= this.controls.volume.slider.offset().top;
      if (y < 0) y = 0;
      if (y > height) y = height;
      y = height - y;
      this.volume(y / height, y == 0);
      this.halt(ev);
    },
    halt(ev) {
      ev.preventDefault();
      ev.stopPropagation();
    },
    volume(volume, muted) {
      this.dom.find('.volume .indicator i').attr('class', muted ? 'fa fa-volume-off' : volume < 0.33 ? 'fa fa-volume-down' : volume < 0.66 ? 'fa fa-volume-mid' : 'fa fa-volume-up');
      if (this.video) this.video.volume = volume;
      if (muted) volume = 0;
      volume *= 100;
      this.controls.volume.bob.css('bottom', `${volume}%`);
      this.controls.volume.fill.css('top', `${100 - volume}%`);
    },
    muteUnmute() {
      this.checkstart();
      this.video.muted = !this.video.muted;
      this.volume(this.video.volume, this.video.muted);
    },
    descriptive(t) {
      const times = [];
      t = Math.floor(t);
      while (t >= 60) {
        times.push(t % 60);
        t = Math.floor(t / 60);
      }
      times.push(t);
      if (times.length < 2) times.push(0);
      return times.reverse().join(':');
    },
    drawPreview(progress) {
      if (!this.video) return;
      const duration = parseInt(this.video.duration) || 0;
      let time = duration * progress;
      this.controls.track.preview.css('left', `${(time / duration) * 100}%`);
      this.controls.track.preview.attr('data-time', this.descriptive(time));
      if (!this.audioOnly) {
        time = time -= time % 5;
        if (this.preview && this.preview.time != time) {
          this.preview.time = time;
          if (!this.preview.video) {
            const temp_vid = this.preview.video = Player.createVideoElement(this)[0];
            const canvas = this.preview;
            const context = this.preview.getContext('2d');
            temp_vid.addEventListener('loadeddata', function load_time() {
              this.currentTime = time;
              this.removeEventListener('loadeddata', load_time);
            });
            temp_vid.addEventListener('seeked', () => {
              context.drawImage(temp_vid, 0, 0, canvas.width, canvas.height);
            });
          } else {
            if (Player.isready(this.preview.video)) {
              this.preview.video.currentTime = time;
            }
          }
        }
      }
    }
  };

  const aspect = 16 / 9;
  function resize() {
    const me = $(this);
    me.css({
      'margin-bottom': '', height: `${me.width() / aspect}px`
    });
  }
  const ev = {which:1};
  function removeContext() {
    if (this.getPlayerObj) this.getPlayerObj().removeContext(ev);
  }

  function TapToggler(owner) {
    let hover_timeout = null;
    let touching = false;
    let hover_flag = 0;
    return owner.toggler = {
      update(ev) {
        if (!touching) touching = true;
        owner.addClass('hover');
        hover_flag++;
        if (hover_timeout) {
          clearTimeout(hover_timeout);
          hover_timeout = null;
        }
        hover_timeout = setTimeout(() => {
          owner.removeClass('hover');
          hover_timeout = null;
          hover_flag = 0;
        }, 1700);
      },
      touching() {
        return touching;
      },
      interactable() {
        return !touching || hover_flag > 1;
      }
    };
  }

  $(() => {
    $('.video').each(function() {
      const el = $(this);
      if (!el.attr('data-pending') && !el.hasClass('unplayable')) (new Player()).constructor(el);
    });
  });

  $(window).on('resize', () => {
    $('.video').each(resize);
  });

  $(window).on('resize blur', () => {
    $('.player').each(removeContext);
  });

  $doc.on('mousemove', () => {
    fadeTimer = 2;
    if (Player.fullscreenPlayer) {
      Player.fullscreenPlayer.controls.css('opacity', 1);
      Player.fullscreenPlayer.player.find('.playing').css('cursor', '');
      if (fadeControl == null) fadeControl = setTimeout(controlsFade, 1000);
    }
  });
}());
