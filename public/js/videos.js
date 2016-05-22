/*
Initialises basic video playback funtionality.

Copyright Project Vinyl Foundation 2016
*/

function Player() {}
(function() {
  /* Standardise fullscreen API */
  (function(p) {
    Player.requestFullscreen = p.requestFullscreen || p.mozRequestFullScreen || p.msRequestFullscreen || p.webkitRequestFullscreen || function() {};
    Player.exitFullscreen = document.exitFullscreen || document.mozCancelFullScreen || document.msExitFullscreen || document.webkitExitFullscreen || function() {};
  })(Element.prototype);
  Player.isFullscreen = !1;
  Player.onFullscreen = function(func) {
    $(document).on('webkitfullscreenchange mozfullscreenchange fullscreenchange', func);
  }
  Player.isFullscreen = function() {
    return document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
  };
  Player.speeds = [
    {name: 'Double', value: 2},
    {name: '1.5x', value: 1.5},
    {name: '1.25x', value: 1.25},
    {name: 'Normal', value: 1},
    {name: '0.5x', value: 0.5},
    {name: '0.25x', value: 0.25}
  ];
  Player.generate = function(holder) {
    holder.html('<div class="player" >\
								<span class="playing"></span>\
                <span class="suspend" style="display:none"><i class="fa fa-pulse fa-spinner"></i></span>\
								<span class="pause resize-holder">\
									<span class="playback"></span>\
									<h1 class="resize-target"><a><span class="title">undefined</span> - <span class="artist">undefined</span></a></h1>\
								</span>\
							</div>\
							<div class="controls">\
								<ul>\
									<li class="track">\
										<span class="fill"></span>\
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
    Player.fullscreenPlayer.controls.css('opacity', 0);
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
      Player.fullscreenPlayer.onfullscreen(Player.isFullscreen());
    }
  });
  Player.prototype = {
    constructor: function(el) {
      if (!el.children().length) Player.generate(el);
      var me = this;
      
      this.dom = el;
      this.player = el.find('.player');
      this.suspend = el.find('.suspend');
      this.contextmenu = el.find('.contextmenu');
      this.contextmenu.unset = 1;
      this.player[0].getPlayerObj = function() {
        return me;
      };
      this.video = null;
      this.controls = el.find('.controls');
      this.source = el.attr('data-video');
      if (!this.source) {
        this.source = el.attr('data-audio');
        this.audioOnly = true;
      }
      resize.apply(el);
      
      el.find('.title').text(this.title = el.attr('data-title'));
      el.find('.artist').text(this.artist = el.attr('data-artist'));
      
      el.on('click', function(ev) {
        if (!me.removeContext(ev)) me.toggleVideo();
      });
      el.on('contextmenu', function(ev) {
        me.showContext(ev);
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
        this.controls.volume = this.controls.find('.volume')
        this.controls.volume.on('click', function(ev) {
          if (!me.removeContext(ev)) me.muteUnmute();
        });
        this.controls.volume.bob = this.controls.find('.volume .bob');
        this.controls.volume.fill = this.controls.find('.volume .fill');
        this.controls.volume.bob.on('mousedown', function(ev) {
          if (!me.removeContext(ev)) me.startChangeVolume(ev);
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
      if (ev.which != 1) {
        this.contextmenu.css({
          top: ev.pageY - this.dom.offset().top,
          left: ev.pageX - this.dom.offset().left,
          display: 'table'
        });
        this.contextmenu.css('opacity', '1');
        this.halt(ev);
      }
    },
    setEmbed: function(id) {
      this.player.find('.pause h1').css('pointer-events', 'initial');
      var link = this.player.find('.pause h1 a');
      link.attr({
        target: '_blank', href: 'view.html?' + id + '-' + this.title
      });
      link.on('click', function (ev) {
        ev.stopPropagation();
      });
    },
    addContext: function(title, s, callback) {
      var item = $('<li><div class="label">' + title + '</div></li>');
      var value = $('<div class="value" ></div>');
      item.append(value);
      function val(s) {
        value.html(typeof s === 'boolean' ? (s ? '<i class="fa fa-check" />' : '') : s);
      }
      val(s);
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
      if (Player.fullscreenPlayer && Player.fullscreenPlayer != this) {
        Player.fullscreenPlayer.fullscreen(false);
      }
      if (fadeControl != null) clearTimeout(fadeControl);
      if (on) {
        Player.requestFullscreen.apply(this.dom[0]);
        fadeControl = setTimeout(controlsFade, 1000);
      } else if (Player.fullscreenPlayer == this) {
        Player.exitFullscreen.apply(document);
        this.controls.css('opacity', '');
      }
      Player.fullscreenPlayer = on ? this : null;
      return on;
    },
    onfullscreen: function(on) {
      this.controls.fullscreen.html(on ? '<i class="fa fa-restore"></i>' : '<i class="fa fa-arrows-alt"></i>');
    },
    loop: function(on) {
      this.__loop = on;
      if (this.video) this.video.loop = on;
      return on;
    },
    checkstart: function() {
      if (!this.video) this.start();
    },
    start: function() {
      if (!this.video) {
        var video;
        if (this.audioOnly) {
          video = $('<audio src="/stream/' + this.source + '.mp3" type="audio/mpeg"></audio>');
        } else {
          video = $('<video src="/stream/' + this.source + '.webm" type="video/webm; codecs=\'vp8,vorbis\'"></video>');
        }
        this.video = video[0];
        this.player.find('.playing').append(this.video);
        var me = this;
        video.on('abort pause error ended', function() {
          me.pause();
        });
        video.on('suspend waiting', function() {
          me.suspend.css('display', 'block');
        });
        video.on('volumechange', function() {
          me.volume(me.video.volume, me.video.muted || me.video.volume == 0);
        });
        video.on('timeupdate', function() {
          me.track(me.video.currentTime, parseInt(me.video.duration));
        });
        this.volume(me.video.volume, video.muted);
      }
      this.player.addClass('playing');
      this.video.loop = !!this.__loop;
      sendMessage(this);
      this.video.play();
      this.volume(this.video.volume, this.video.muted);
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
      this.video.pause();
      this.suspend.css('display', 'none');
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
      this.suspend.css('display', 'none');
    },
    changetrack: function(progress) {
      var duration = parseInt(this.video.duration);
      var time = duration * progress;
      this.video.currentTime = time;
      this.track(time, duration);
    },
    jump: function(ev) {
      var x = ev.pageX - this.controls.track.offset().left;
      if (x < 0) x = 0;
      if (x > this.controls.track.width()) x = this.controls.track.width();
      this.changetrack(x / this.controls.track.width());
      this.halt(ev);
    },
    startChange: function(ev, bob) {
      this.checkstart();
      var me = this;
      var func = function(ev) {
        me.jump(ev);
      }
      this.dom.addClass('tracking');
      $(document).on('mousemove', func);
      $(document).one('mouseup', function() {
        $(document).off('mousemove', func);
        me.dom.removeClass('tracking');
      });
      this.halt(ev);
    },
    startChangeVolume: function(ev) {
      this.checkstart();
      var me = this;
      var func = function(ev) {
        me.changeVolume(ev);
      };
      this.dom.addClass('voluming');
      $(document).on('mousemove', func);
      $(document).one('mouseup', function() {
        $(document).off('mousemove', func);
        me.dom.removeClass('voluming');
      });
      this.halt(ev);
    },
    changeVolume: function(ev) {
      var height = this.controls.volume.slider.height();
      if (height == 0) return;
      var y = ev.pageY - this.controls.volume.slider.offset().top;
      if (y < 0) y = 0;
      if (y > height) y = height;
      y = height - y;
      this.video.volume = y / height;
      this.volume(y / height, y == 0);
      this.halt(ev);
    },
    halt: function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
    },
    volume: function(volume, muted) {
      this.dom.find('.volume .indicator i').attr('class', muted ? 'fa fa-volume-off' : volume < 0.33 ? 'fa fa-volume-down' : volume < 0.66 ? 'fa fa-volume-mid' : 'fa fa-volume-up');
      if (muted) volume = 0;
      volume *= 100;
      this.controls.volume.bob.css('bottom', volume + '%');
      this.controls.volume.fill.css('top', (100 - volume) + '%');
    },
    muteUnmute: function() {
      this.checkstart();
      this.video.muted = !this.video.muted;
      this.volume(this.video.volume, this.video.muted);
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
  
  $('.video').each(function() {
    var el = $(this);
    if (!el.attr('data-pending')) (new Player()).constructor(el);
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
      if (fadeControl == null) fadeControl = setTimeout(controlsFade, 1000);
    }
  });
})();