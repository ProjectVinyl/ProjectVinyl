var Uploader = (function() {
  var INSTANCES = [];
  var INDEX = 0;
  var uploadingQueue = {
    running: false,
    items: [],
    enqueue: function(me) {
      if (me.isReady()) {
        this.items.push(me);
        return this.poke();
      }
    },
    enqueueAll: function(args) {
      this.items.push.apply(this.items, args);
      return this.poke();
    },
    poke: function() {
      var self = this;
      if (this.running) return;
      this.running = true;
      return this.tick(function() {
        var i = 0;
        while (self.items.length > 0 && !(i = self.items.shift()).isReady());
        if (i && i.isReady()) return i;
      });
    },
    tick: function(next) {
      var self = this;
      var uploader = next();
      this.running = !!uploader;
      if (this.running) {
        uploader.tab.addClass('loading');
        uploader.tab.addClass('waiting');
        ajax.form(uploader.form, {
          success: function(data) {
            uploader.complete(data.ref);
            if (next) next = self.tick(next);
          },
          error: function(message, msg, response) {
            uploader.error();
            message.text(response);
          },
          update: function(e, percentage) {
            uploader.update(percentage);
            if (next && percentage > 100) next = self.tick(next);
          },
        });
      }
      return 0;
    }
  };
  
  function Validator(el) {
    var self = this;
    
    this.el = el;
    
    this.hasCover = false;
    this.needsCover = toBool(el[0].dataset['needs-cover']);
    
    this.el.notify = this.el.find('.notify');
    this.el.notify.bobber = this.el.notify.find('.bobber');
    this.el.info = this.el.find('.info');
    
    this.time = this.el.find('#time');
    this.lastTime = -1;
    
    this.cover = this.el.find('#cover-upload');
    this.cover.input = this.cover.find('input[type=file]');
    this.cover.preview = this.cover.find('.preview');
    
    this.video = this.el.find('#video-upload');
    this.video.input = this.video.find('input[type=file]');
    
    this.video.on('accept', function(e, file) {
      this.needsCover = !!file.mime.match(/audio\//);
      this.accept(file);
    });
    
    this.cover.on('accept', function() {
      self.hasCover = true;
      self.validateInput();
    });
    
    this.el.find('.tab[data-tab="thumbpick"]').on('tabblur', function() {
      self.lastTime = self.time.val();
      self.time.val(-1);
      self.validateInput();
    }).on('tabfocus', function() {
      self.time.val(self.lastTime);
      self.validateInput();
    });
  }
  Validator.prototype = {
    isReady: function() {
      return this.hasFile && (this.hasCover || !this.needsCover) && this.ready;
    },
    notify: function(msg) {
      this.el.notify.addClass('shown');
      this.el.notify.bobber.text(msg);
    },
    info: function(msg) {
      this.el.info.css('display', '');
      this.el.info.text(msg);
    }
  };
  
  function Uploader() {
    var self = this;
    
    this.id = INDEX++;
    this.el = $($('#template').html().replace(/\{id\}/g, this.id));
    
    $('#uploader_frame > .tab.selected').removeClass('selected');
    $('#uploader_frame').append(this.el);
    this.tab = $('<li data-target="new[' + this.id + ']" class="button hidden"><span class="progress"><span class="fill"></span></span class="label"><span>untitled' + (this.id > 0 ? ' ' + this.id : '') + '</span><i class="fa fa-close" ></i></li>');
    this.tab.label = this.tab.find('.label');
    this.tab.progress = this.tab.find('.progress');
    this.tab.progress.fill = this.tab.progress.find('.fill');
    $('#new_tab_button').before(this.tab);
    
    this.form = this.el.find('form');
    this.videoTitle = this.el.find('#video_title');
    this.videoTitle.input = this.videoTitle.find('input');
    this.videoDescription = this.el.find('textarea.comment-content');
    this.title = this.el.find('#video_title .content');
    this.tagEditor = TagEditor.getOrCreate(this.el.find('.tag-editor')[0]);
    
    this.source = this.el.find('#video_source');
    this.srcNeeded = false;
    
    BBC.init(this.videoTitle[0]);
    initFileSelect(this.video);
    initFileSelect(this.cover);
    
    setTimeout(function() {
      self.tab.removeClass('hidden');
    }, 1);
    this.tab.find('i').on('click', function() {
      self.dispose();
    });
    this.form.on('submit', function(e) {
      uploadingQueue.enqueue(self);
      e.preventDefault();
      e.stopPropagation();
    });
    
    this.el.find('#new_video').on('tagschange', function() {
      self.validateInput();
    }).on('change', 'h1#video_title input', function() {
      self.validateInput();
    });
    
    this.el.find('h1.resize-target').each(function() {
      resizeFont($(this));
    });
    
    Validator.call(this, this.el);
    
    focusTab(this.tab);
    
    INSTANCES.push(this);
  }
  
  Uploader.uploadAll = function() {
    uploadingQueue.enqueueAll(INSTANCES);
  };
  
  Uploader.prototype = extendObj({
    initPlayer: function() {
      this.player = new ThumbPicker();
      this.player.constructor(this.el.find('.video'));
    },
    showUI: function(title) {
      this.el.find('.hidden').removeClass('hidden');
      this.el.find('.shown').addClass('hidden').removeClass('shown');
      this.tab.label.text(title);
      this.tab.attr(title);
    },
    accept: function(file) {
      if (this.video.hasClass('shown')) {
        var title = this.cleanup(file.title);
        this.title.text(title);
        this.videoTitle.input.val(title);
        this.showUI(file.title + '.' + file.type);
      }
      if (!this.player) this.initPlayer();
      if (this.needsCover) {
        this.player.load(null);
        this.el.find('li[data-target="thumbupload_' + this.id + '"]').click();
        this.el.find('li[data-target="thumbpick_' + this.id + '"]').attr('data-disabled', '1');
      } else {
        if (Player.canPlayType(file.mime)) {
          this.player.load(file.data);
          this.el.find('li[data-target="thumbpick_' + this.id + '"]').removeAttr('data-disabled').click();
        } else {
          this.el.find('li[data-target="thumbupload_' + this.id + '"]').click();
          this.el.find('li[data-target="thumbpick_' + this.id + '"]').attr('data-disabled', '1');
        }
      }
      this.hasFile = true;
      this.validateInput();
    },
    cleanup: function(title) {
      return title.toLowerCase().replace(/^[0-9]*/g, '').replace(/[-_]|[^a-z\s]/gi, ' ').replace(/(^|\s)[a-z]/g, function(i) {
        return i.toUpperCase();
      }).trim();
    },
    validateInput: function() {
      var tit = this.videoTitle.input.val();
      
      this.ready = false;
      if (!tit || tit == '') return this.notify('You need to provide a title.');
      if (this.needsCover && !this.hasCover) return this.notify('Audio files require a cover image.');
      var tags = this.tagEditor.tags;
      var src = this.source.val();
      if (!src || src == '') {
        this.srcNeeded = false;
        each(tags, function(arr, i) {
          if (arr[i].name.trim().toLowerCase() == 'source needed') {
            this.srcNeeded = true;
          }
        }, this);
        if (!this.srcNeeded) {
          this.info('You have not provided a source. If you know what it is add it to the source field, otherwise consider tagging this video as \'source needed\' so others know to search for one.');
        } else {
          this.el.info.css('display', 'none');
        }
      } else {
        this.el.info.css('display', 'none');
      }
      if (tags.length == 0) return this.notify('You need at least one tag.');
      if (tags.length == 1 && tags[0].name.trim().toLowerCase() == 'music') return this.notify('\'music\' is implied. Tags should be more specific than that. Do you perhaps know who the artist is?');
      this.ready = true;
      this.el.notify.removeClass('shown');
    },
    update: function(percentage) {
      this.tab.addClass('uploading');
      this.tab.progress.fill.css('width', percentage + '%');
      if (percentage >= 100) this.tab.addClass('waiting');
    },
    complete: function(ref) {
      this.form.removeClass('uploading');
      this.tab.removeClass('uploading');
      this.ready = false;
      if (this.tab.hasClass('selected')) {
        focusTab(this.tab.parent().find('li.button:not([data-disabled]):not(.hidden)[data-target]:not([data-target="' + this.id + '"])').first());
      }
      if (ref) {
        this.el.html('Uploading Complete. You can see your new video over <a target="_blank" href="' + ref + '">here</a>.');
      }
    },
    error: function() {
      this.tab.addClass('error');
    },
    dispose: function() {
      INSTANCES.splice(INSTANCES.indexOf(this), 1);
    }
  }, Validator.prototype);
  
  $(function() {
    $('#new_tab_button').on('click', function() {
      new Uploader();
    });
  });
  
  function UploadChecker (el) {
    Validator.call(this, el);
    if (this.needsCover) {
      this.initPlayer();
    }
  }
  UploadChecker.prototype = extendObj({
    initPlayer: function() {
      this.player = new ThumbPicker();
      this.player.constructor(this.el.find('.video'));
      this.player.start();
    },
    accept: function(file) {
      if (this.needsCover && !this.player) this.initPlayer();
      if (Player.canPlayType(file.mime)) {
        this.player.load(file.data);
        this.el.find('li[data-target="thumbpick"]').removeAttr('data-disabled').click();
      } else {
        this.el.find('li[data-target="thumbupload"]').click();
        this.el.find('li[data-target="thumbpick"]').attr('data-disabled', '1');
      }
      this.validateInput();
    },
    validateInput: function() {
      if (this.needsCover && !this.hasCover) return this.notify('Audio files require a cover image.');
      this.el.notify.removeClass('shown');
    }
  }, Validator.prototype);
  
  Uploader.createChecker = function(el) {
    return new UploadChecker(el);
  };
  return Uploader;
})();