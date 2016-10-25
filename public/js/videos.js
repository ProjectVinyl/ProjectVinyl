/*
Initialises basic video playback funtionality.

Copyright Project Vinyl Foundation 2016
*/

function Player() {}
(function() {
  var KEY_SPACE = 32;
  /* Standardise fullscreen API */
  (function(p) {
    Player.requestFullscreen = p.requestFullscreen || p.mozRequestFullScreen || p.msRequestFullscreen || p.webkitRequestFullscreen || function() {};
    Player.exitFullscreen = document.exitFullscreen || document.mozCancelFullScreen || document.msExitFullscreen || document.webkitExitFullscreen || function() {};
    Player.isFullscreen = function() {
      return document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
    }
  })(Element.prototype);
  Player.onFullscreen = function(func) {
    $(document).on('webkitfullscreenchange mozfullscreenchange fullscreenchange', func);
  };
  var VIDEO_ELEMENT = document.createElement('video');
  Player.canPlayType = function(mime) {
    return !!(mime = VIDEO_ELEMENT.canPlayType(mime)).length && mime !== 'no';
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
		if (!player.source || player.source == "0") return $('<video></video>');
		if (typeof player.source === 'string' && player.source.indexOf('blob') == 0) return $('<video src="' + player.source + '"></video>');
    return $('\
            <video>\
             <source src="/stream/' + player.source + '.webm" type="video/webm"></source>\
             <source src="/stream/' + player.source + player.mime[0] + '" type="' + player.mime[1] + '"></source>\
            </video>');
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
      case video.error.MEDIA_ERR_SRC_NOT_SUPPORTED: return 'Codec no supported';
      default: return 'Unknown Error';
    }
  };
  Player.noise = (function() {
    var canvas = null, ctx = null;
    var toggle = true;
    function noise(ctx) {
      var w = ctx.canvas.width,
          h = ctx.canvas.height,
          idata = ctx.createImageData(w, h),
          buffer32 = new Uint32Array(idata.data.buffer),
          len = buffer32.length,
          i = 0;
      for(; i < len;) buffer32[i++] = ((255 * Math.random())|0) << 24;
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
    }
  })();
  Player.generate = function(holder) {
    holder.prepend('<div class="player" >\
								<span class="playing"></span>\
                <span class="error"><span class="error-message"></span></span>\
                <span class="suspend" style="display:none"><i class="fa fa-pulse fa-spinner"></i></span>\
								<span class="pause resize-holder">\
									<span class="playback"></span>\
									<h1 class="resize-target" style="display:none;"><a><span class="title">undefined</span> - <span class="artist">undefined</span></a></h1>\
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
  var fadeControl = null;
  function controlsFade() {
    if (Player.fullscreenPlayer) {
      Player.fullscreenPlayer.controls.css('opacity', 0);
      Player.fullscreenPlayer.player.find('.playing').css('cursor', 'none');
    }
    fadeControl = null;
  }
  function attachMessageListener(me) {
    $(window).on('storage', function(ev) {
      if (ev.originalEvent.key === '::activeplayer' && ev.originalEvent.newValue != me.__seed) {
        me.pause();
      }
    });
  }
  function sendMessage(me) {
    me.__seed = '' + ((parseInt(localStorage['::activeplayer'] || '0') + 1) % 3);
    localStorage.setItem('::activeplayer', me.__seed);
  }
  Player.onFullscreen(function() {
    if (Player.fullscreenPlayer) {
      Player.fullscreenPlayer.fullscreen(Player.isFullscreen());
    }
  });
  function canGen(childs) {
    return !childs.length || (childs.length == 1 && childs.first().hasClass('playlist'));
  }
  Player.prototype = {
    constructor: function(el) {
      if (canGen(el.children())) Player.generate(el);
      var me = this;
      
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
      this.mime = (el.attr('data-mime') || ".mp4|video/m4v").split('|');
      this.controls = el.find('.controls');
      this.source = el.attr('data-video');
      if (!this.source) {
        this.source = el.attr('data-audio');
        this.audioOnly = true;
        this.preview = $('<img src="/cover/' + this.source + '-small.png" />')[0];
      } else {
        this.preview = $('<canvas />')[0];
      }
      
      this.time = el.attr('data-time');
      
      resize.apply(el);
      
      el.find('h1 .title').text(this.title = el.attr('data-title'));
      el.find('h1 .artist').text(this.artist = el.attr('data-artist'));
      
      new TapToggler(this.dom);
      el.on('click', function(ev) {
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
      el.on('contextmenu', function(ev) {
        me.showContext(ev);
      });
      var active_touches = [];
      var tapped = false;
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
          tapped = setTimeout(function() {
            tapped = null;
          }, 500);
        }
        me.dom.toggler.update(ev);
        active_touches.push({identifier: ev.identifier});
      });
      el.on('touchmove touchend touchcancel', function(ev) {
        for (var i = 0; i < active_touches; i++) {
          if (active_touches[i].identifier == ev.identifier) {
            active_touches.splice(i, 1);
          }
        }
      });
      this.__loop = false;
      this.__speed = 3;
      this.contextmenu.on('click', this.halt);
      this.addContext('Loop', false, function(val) {
        val(me.loop(!me.__loop));
      });
      this.addContext('Speed', me.speed(me.__speed), function(val) {
        me.__speed = (me.__speed + 1) % Player.speeds.length;
        val(me.speed(me.__speed));
      });
      
      $(document).on('click', function(ev) {
        me.removeContext(ev);
      });
      $(document).on('keydown', function(ev) {
        if (ev.which == KEY_SPACE) {
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
        this.controls.track.on('mousedown', function(ev) {
          if (!me.removeContext(ev)) {
            me.checkstart();
            me.jump(ev);
          }
        });
        this.controls.track.bob = this.controls.find('.track .bob');
        this.controls.track.fill = this.controls.find('.track .fill');
        this.controls.track.bob.on('mousedown', function(ev) {
          if (!me.removeContext(ev)) me.startChange(ev);
        });
        this.controls.track.bob.on('touchstart', function(ev) {
          me.removeContext(ev);
          me.startChange(ev);
        });
        this.controls.track.preview = el.find('.track .previewer');
        this.controls.track.preview.append(this.preview);
        this.controls.track.on('mousemove', function(ev) {
          me.drawPreview(me.evToProgress(ev));
        });
        this.controls.volume = this.controls.find('.volume');
        this.controls.volume.on('click', function(ev) {
          if (!me.removeContext(ev)) {
            if (me.controls.volume.toggler.interactable()) {
              me.muteUnmute(); 
            }
          }
        });
        new TapToggler(this.controls.volume);
        this.controls.volume.on('touchstart', function(ev) {
          me.controls.volume.toggler.update(ev);
          me.halt(ev);
        });
        
        this.controls.volume.bob = this.controls.find('.volume .bob');
        this.controls.volume.fill = this.controls.find('.volume .fill');
        this.controls.volume.bob.on('mousedown', function(ev) {
          if (!me.removeContext(ev)) me.startChangeVolume(ev);
        });
        this.controls.volume.bob.on('touchstart', function(ev) {
          me.removeContext(ev);
          me.startChangeVolume(ev);
        });
        this.controls.volume.slider = this.controls.find('.volume .slider');
        this.controls.volume.slider.on('mousedown', function(ev) {
          if (!me.removeContext(ev)) {
            me.checkstart();
            me.changeVolume(ev);
          }
        });
        this.controls.fullscreen = this.controls.find('.fullscreen .indicator');
        this.controls.find('.fullscreen').on('click', function(ev) {
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
        this.addContext('Autoplay', this.autoplay(!document.cookie.replace(/(?:(?:^|.*;\s*)autoplay\s*\=\s*([^;]*).*$)|^.*$/, "$1")), function() {
          val(me.__autoplay = !me.__autoplay);
          document.cookie = 'autoplay=' + (on ? ';' : '1;');
        });
      }
      return this;
    },
    removeContext: function(ev) {
      if (ev.which == 1 && this.contextmenu.css('display') == 'table') {
        this.contextmenu.css('opacity', '');
        var me = this;
        setTimeout(function() {
          me.contextmenu.css('display', '');
        }, 100);
        return 1;
      }
      return 0;
    },
    showContext: function(ev) {
      var y = ev.pageY;
      var x = ev.pageX;
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
    setEmbed: function(id) {
      this.player.find('.pause h1').css({
        'pointer-events': 'initial', 'display': ''
      });
      var link = this.player.find('.pause h1 a');
      link.attr({
        target: '_blank', href: '/view/' + id + '-' + this.title
      });
      link.on('click', function (ev) {
        ev.stopPropagation();
      });
    },
    setPlaylist: function(album_id, album_index) {
      this.album = {
        id: album_id, index: album_index
      };
      this.dom.playlist = $('.playlist');
      this.dom.playlist.link = $('<div class="playlist-toggle"><i class="fa fa-list" /></div>');
      this.dom.append(this.dom.playlist.link);
      var me = this;
      this.dom.playlist.link.on('click', function(ev) {
        me.dom.playlist.toggleClass('visible');
        me.halt(ev);
      });
      this.addContext('Autoplay', this.autoplay(!document.cookie.replace(/(?:(?:^|.*;\s*)autoplay\s*\=\s*([^;]*).*$)|^.*$/, "$1")), function() {
        val(me.__autoplay = !me.__autoplay);
        document.cookie = 'autoplay=' + (on ? ';' : '1;');
      });
      this.dom.playlist.on('click', '.items a, #playlist_next, #playlist_prev', function(ev) {
        var next = $(this);
        ajax.get(next.attr('href'), function(json) {
          me.redirect = next.attr('href');
          me.loadAttributesAndRestart(json);
          if (json.next) {
            $('#playlist_next').attr('href', json.next);
          }
          if (json.prev) {
            $('#playlist_prev').attr('href', json.prev);
          }
          $('.playlist a.selected').removeClass('selected');
          var selected = $('.playlist a[data-id=' + json.id + ']');
          selected.addClass('selected');
          scrollTo(selected, '.playlist .scroll-container');
        });
        me.halt(ev);
      });
    },
    addContext: function(title, initial, callback) {
      var item = $('<li><div class="label">' + title + '</div></li>');
      var value = $('<div class="value" ></div>');
      item.append(value);
      function val(s) {
        value.html(typeof s === 'boolean' ? (s ? '<i class="fa fa-check" />' : '') : s);
      }
      val(initial);
      item.on('click', function() {
        callback(val);
      });
      this.contextmenu.append(item);
    },
    speed: function(speed) {
      speed = Player.speeds[speed] || Player.speeds[3];
      if (this.video) this.video.playbackRate = speed.value;
      return speed.name;
    },
    fullscreen: function(on) {
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
            this.redirect += (this.redirect.indexOf('?') >= 0 ? "&" : "?") + "t=" + this.video.currentTime;
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
    onfullscreen: function(on) {
      this.controls.fullscreen.html(on ? '<i class="fa fa-restore"></i>' : '<i class="fa fa-arrows-alt"></i>');
      if (!on) this.player.find('.playing').css('cursor', '');
    },
    autoplay: function(on) {
      this.__autoplay = on;
      if (on) {
        this.loop(false);
      }
      return on;
    },
    loop: function(on) {
      this.__loop = on;
      if (this.video) this.video.loop = on;
      return on;
    },
    checkstart: function() {
      if (!this.video) this.start();
    },
    loadAttributesAndRestart: function(attr) {
      this.dom.css('background-image', "url('/cover/" + attr.source + ".png')");
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
		load: function(data) {
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
			if (!this.thumbtrack) {
				this.thumbtrack = true;
				var me = this;
				this.video.addEventListener('loadedmetadata', function() {
					me.changetrack(0.5);
				});
			}
		},
    start: function() {
      if (!this.video) {
        var video;
        if (this.audioOnly && this.source) {
          video = $('<audio src="/stream/' + this.source + this.mime[0] + '" type="' + this.mime[1] + '"></audio>');
        } else {
          video = Player.createVideoElement(this);
        }
        this.video = video[0];
        if (this.time) {
          this.video.currentTime = parseInt(this.time);
        }
        this.player.find('.playing').append(this.video);
        var me = this;
        video.on('pause', function() {
          me.pause();
        });
        video.on('play', function() {
          me.player.addClass('playing');
          me.player.removeClass('stopped');
          me.player.removeClass('paused');
          me.player.removeClass('error');
          me.video.loop = !!me.__loop;
          sendMessage(me);
          me.volume(this.volume, this.muted);
        });
        video.on('abort error', function(e) {
          me.error(e);
        });
        video.find('source').last().on('error', function(e) {
          me.error(e);
        });
        video.on('ended', function() {
          if (me.__autoplay) {
            var next = $('#playlist_next');
            if (next.length) {
              if (Player.fullscreenPlayer == me || me.album) {
                ajax.get(next.attr('href'), function(json) {
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
                  var selected = $('.playlist a[data-id=' + json.id + ']');
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
        var suspendTimer = null;
        video.on('suspend waiting', function() {
          if (!suspendTimer) {
            suspendTimer = setTimeout(function() {
              me.suspend.css('display', 'block');
            }, 3000);
          }
        });
        video.on('volumechange', function() {
          me.volume(me.video.volume, me.video.muted || me.video.volume == 0);
        });
        video.on('timeupdate', function() {
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
    stop: function() {
      this.pause();
      this.changetrack(0);
      this.video.parentNode.removeChild(this.video);
      this.video = null;
      this.suspend.css('display', 'none');
    },
    pause: function() {
      this.player.removeClass('playing');
      this.player.addClass('paused');
      if (this.video) this.video.pause();
      this.suspend.css('display', 'none');
			return true;
    },
    error: function(e) {
      this.pause();
      this.player.addClass('stopped');
      this.player.addClass('error');
      var message = Player.errorMessage(this.video);
      this.player.error.message.text(message);
      if (!this.noise) {
        this.noise = Player.noise();
        this.player.error.append(this.noise);
      }
      console.warn(message);
      console.log(e);
    },
    toggleVideo: function() {
      if (!this.player.hasClass('playing')) {
        this.start();
      } else {
        this.pause();
      }
    },
    track: function(time, duration) {
      var percentFill = (time/duration) * 100;
      this.controls.track.bob.css('left', percentFill + '%');
      this.controls.track.fill.css('right', (100 - percentFill) + '%');
      if (this.dom.toggler.touching()) {
        this.controls.track.preview.css('left', percentFill + '%');
        this.controls.track.preview.attr('data-time', this.descriptive(time));
      }
      this.suspend.css('display', 'none');
    },
    changetrack: function(progress) {
			if (progress < 0) progress = 0;
			if (progress > 1) progress = 1;
      var duration = parseFloat(this.video.duration) || 0;
      var time = duration * progress;
      this.video.currentTime = time;
      this.track(time, duration);
    },
    jump: function(ev) {
      var progress = this.evToProgress(ev);
      this.changetrack(progress);
      if (ev.originalEvent.touches) {
        this.drawPreview(progress);
      }
      this.halt(ev);
    },
    evToProgress: function(ev) {
      var x = ev.pageX;
      if (!x && ev.originalEvent.touches) {
        x = ev.originalEvent.touches[0].pageX || 0;
      }
      
      x -= this.controls.track.offset().left;
      if (x < 0) x = 0;
      if (x > this.controls.track.width()) x = this.controls.track.width();
      return x / this.controls.track.width();
    },
    startChange: function(ev, bob) {
      this.checkstart();
      var me = this;
      var func = function(ev) {
        me.jump(ev);
      }
      this.dom.addClass('tracking');
      $(document).on('mousemove touchmove', func);
      var ender = function() {
        $(document).off('mouseup touchend touchcancel', ender);
        $(document).off('mousemove touchmove', func);
        me.dom.removeClass('tracking');
      }
      $(document).one('mouseup touchend touchcancel', ender);
      this.halt(ev);
    },
    startChangeVolume: function(ev) {
      this.checkstart();
      var me = this;
      var func = function(ev) {
        me.changeVolume(ev);
      };
      this.dom.addClass('voluming');
      $(document).on('mousemove touchmove', func);
      var ender = function() {
        $(document).off('mouseup touchend touchcancel', ender);
        $(document).off('mousemove touchmove', func);
        me.dom.removeClass('voluming');
      }
      $(document).one('mouseup touchend touchcancel', ender);
      this.halt(ev);
    },
    changeVolume: function(ev) {
      var height = this.controls.volume.slider.height();
      if (height == 0) return;
      var y = ev.pageY;
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
    halt: function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
    },
    volume: function(volume, muted) {
      this.dom.find('.volume .indicator i').attr('class', muted ? 'fa fa-volume-off' : volume < 0.33 ? 'fa fa-volume-down' : volume < 0.66 ? 'fa fa-volume-mid' : 'fa fa-volume-up');
      if (this.video) this.video.volume = volume;
      if (muted) volume = 0;
      volume *= 100;
      this.controls.volume.bob.css('bottom', volume + '%');
      this.controls.volume.fill.css('top', (100 - volume) + '%');
    },
    muteUnmute: function() {
      this.checkstart();
      this.video.muted = !this.video.muted;
      this.volume(this.video.volume, this.video.muted);
    },
    descriptive: function(t) {
      var times = [];
      t = Math.floor(t);
      while (t >= 60) {
        times.push(t % 60);
        t = Math.floor(t / 60);
      }
      times.push(t);
      if (times.length < 2) times.push(0);
      return times.reverse().join(':');
    },
    drawPreview: function(progress) {
      if (!this.video) return;
      var duration = parseInt(this.video.duration) || 0;
      var time = duration * progress;
      this.controls.track.preview.css('left', ((time/duration) * 100) + '%');
      this.controls.track.preview.attr('data-time', this.descriptive(time));
      if (!this.audioOnly) {
        time = time -= time % 5;
        if (this.preview && this.preview.time != time) {
          this.preview.time = time;
          if (!this.preview.video) {
            var temp_vid = this.preview.video = Player.createVideoElement(this)[0];
            var canvas = this.preview;
            var context = this.preview.getContext('2d');
            temp_vid.addEventListener('loadeddata', function() {
              temp_vid.currentTime = time;
            });
            temp_vid.addEventListener('seeked', function() {
              context.drawImage(temp_vid, 0, 0, canvas.width, canvas.height);
            });
          } else {
            this.preview.video.currentTime = time;
          }
        }
      }
    }
  };
  
  var aspect = 16/9;
  function resize() {
    var me = $(this);
    me.css({
      'margin-bottom': '', 'height': (me.width() / aspect) + 'px'
    });
  }
  var ev = {which:1};
  function removeContext() {
    if (this.getPlayerObj) this.getPlayerObj().removeContext(ev);
  }
  
  function TapToggler(owner) {
    var hover_timeout = null;
    var touching = false;
    var hover_flag = 0;
    return owner.toggler = {
      update: function(ev) {
        if (!touching) touching = true;
        owner.addClass('hover');
        hover_flag++;
        if (hover_timeout) {
          clearTimeout(hover_timeout);
          hover_timeout = null;
        }
        hover_timeout = setTimeout(function() {
          owner.removeClass('hover');
          hover_timeout = null;
          hover_flag = 0;
        }, 1700);
      },
      touching: function() {
        return touching;
      },
      interactable: function() {
        return !touching || hover_flag > 1;
      }
    };
  }


  $('.video').each(function() {
    var el = $(this);
    if (!el.attr('data-pending') && !el.hasClass('unplayable')) (new Player()).constructor(el);
  });
  $(window).on('resize', function() {
    $('.video').each(resize);
  });
  $(window).on('resize blur', function() {
    $('.player').each(removeContext);
  });
  $(document).on('mousemove', function() {
    fadeTimer = 2;
    if (Player.fullscreenPlayer) {
      Player.fullscreenPlayer.controls.css('opacity', 1);
      Player.fullscreenPlayer.player.find('.playing').css('cursor', '');
      if (fadeControl == null) fadeControl = setTimeout(controlsFade, 1000);
    }
  });
})();