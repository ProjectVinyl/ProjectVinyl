var Uploader = (function() {
	var INSTANCES = [];
	var INDEX = 0;
	var uploading_queue = {
		running: false,
		items: [],
		enqueue: function(me) {
			if (me.isReady()) {
				this.items.push(me);
				return this.poke();
			}
		},
		enqueue_all: function(args) {
			this.items.push.apply(this.items, args);
			return this.poke();
		},
		poke: function() {
			if (this.running) return;
			this.running = true;
			var me = this;
			return this.tick(function() {
				var i = undefined;
				while (me.items.length > 0 && !(i = me.items.shift()).isReady());
				if (i && i.isReady()) return i;
			});
		},
		tick: function(next) {
			var uploader = next();
			if (this.running = !!uploader) {
				uploader.tab.addClass('loading');
				uploader.tab.addClass('waiting');
				var me = this;
				ajax.form(uploader.form, {
					success: function(data) {
						uploader.complete(data.ref);
						if (next) next = me.tick(next);
					},
					error: function(message, msg, response) {
						uploader.error();
						message.text(response);
					},
					update: function(e, percentage) {
						uploader.update(percentage);
						if (next && percentage > 100) next = me.tick(next);
					},
				});
			}
			return 0;
		}
	};
	
	function Uploader() {
		this.id = INDEX++;
		this.el = $($('#template').html().replace(/\{id\}/g, this.id));
		
		$('#uploader_frame > .tab.selected').removeClass('selected');
		$('#uploader_frame').append(this.el);
		this.tab = $('<li data-target="new[' + this.id + ']" class="button hidden"><span class="progress"><span class="fill"></span></span class="label"><span>untitled' + (this.id > 0 ? ' ' + this.id : '') + '</span><i class="fa fa-close" ></i></li>');
		this.tab.label = this.tab.find('.label');
		this.tab.progress = this.tab.find('.progress');
		this.tab.progress.fill = this.tab.progress.find('.fill');
		$('#new_tab_button').before(this.tab);
		
		this.el.notify = this.el.find('.notify');
		this.el.notify.bobber = this.el.notify.find('.bobber');
		this.el.info = this.el.find('.info');
		
		this.form = this.el.find('form');
		this.video_title = this.el.find('#video_title');
		this.video_title.input = this.video_title.find('input');
		this.video_description = this.el.find('textarea.comment-content');
		this.title = this.el.find('#video_title .content');
		this.tag_editor = TagEditor.getOrCreate(this.el.find('.tag-editor')[0]);
		this.video = this.el.find('#video-upload');
		this.video.input = this.video.find('input[type=file]');
		this.cover = this.el.find('#cover-upload');
		this.cover.input = this.cover.find('input[type=file]');
		this.cover.preview = this.cover.find('.preview');
		this.source = this.el.find('#video_source');
		
		BBC.init(this.video_title);
		initFileSelect(this.video);
		initFileSelect(this.cover);
		
		this.time = this.el.find('#time');
		this.lastTime = -1;
		this.src_neeeded = false;
		this.has_cover = false;
		this.needs_cover = false;
		this.src_needed = false;
		
		
		var me = this;
		setTimeout(function() {
			me.tab.removeClass('hidden');
		}, 1);
		this.tab.find('i').on('click', function() {
			me.dispose();
		});
		this.form.on('submit', function(e) {
			e.preventDefault();
			e.stopPropagation();
			uploading_queue.enqueue(me);
		});
		this.video.on('accept', function(e, file) {
			me.accept(file);
		});
		this.cover.on('accept', function() {
			me.has_cover = true;
			me.validateInput();
		});
		this.el.find('#new_video').on('tagschange', function() {
			me.validateInput();
		}).on('change', 'h1#video_title input', function() {
			me.validateInput();
		});
		this.el.find('.tab[data-tab="thumbpick"]').on('tabblur', function() {
			me.lastTime = me.time.val();
			me.time.val(-1);
			me.validateInput();
		}).on('tabfocus', function() {
			me.time.val(me.lastTime);
			me.validateInput();
		});
		
		if (typeof focusTab === 'function') {
			focusTab(this.tab);
		} else {
			this.tab.addClass('selected');
		}
		this.el.find('h1.resize-target').each(function() {
			resizeFont($(this));
		});
		
		INSTANCES.push(this);
	}
	
	Uploader.upload_all = function() {
		uploading_queue.enqueue_all(INSTANCES);
	};
  
	Uploader.prototype = {
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
		isReady: function() {
			return this.has_file && (this.has_cover || !this.needs_cover) && this.is_ready;
		},
		accept: function(file) {
			if (this.video.hasClass('shown')) {
				var title = this.cleanup(file.title);
				this.title.text(title);
				this.video_title.input.val(title);
				this.showUI(file.title + '.' + file.type);
			}
			this.needs_cover = !!file.mime.match(/audio\//);
			if (!this.player) this.initPlayer();
			if (this.needs_cover) {
				this.player.load(null);
				this.el.find('li[data-target="thumbupload_' + this.id + '"]').click();
				this.el.find('li[data-target="thumbpick_' + this.id + '"]').attr('data-disabled','1');
			} else {
				if (Player.canPlayType(file.mime)) {
					this.player.load(file.data);
					this.el.find('li[data-target="thumbpick_' + this.id + '"]').removeAttr('data-disabled').click();
				} else {
					this.el.find('li[data-target="thumbupload_' + this.id + '"]').click();
					this.el.find('li[data-target="thumbpick_' + this.id + '"]').attr('data-disabled', '1');
				}
			}
			this.has_file = true;
			this.validateInput();
		},
		cleanup: function(title) {
			return title.toLowerCase().replace(/^[0-9]*/g, '').replace(/[-_]|[^a-z\s]/gi,' ').replace(/(^|\s)[a-z]/g, function(i) {
				return i.toUpperCase()
			}).trim();
		},
		notify: function(msg) {
			this.el.notify.addClass('shown');
			this.el.notify.bobber.text(msg);
		},
		info: function(msg) {
			this.el.info.css('display', '');
			this.el.info.text(msg);
		},
		validateInput: function() {
			this.is_ready = false;
			tit = this.video_title.input.val();
			if (!tit || tit == '') return this.notify('You need to provide a title.');
			if (this.needs_cover && !this.has_cover) return this.notify('Audio files require a cover image.');
			var tags = this.tag_editor.tags;
			var src = this.source.val();
			if (!src || src == '') {
				this.src_needed = false;
				for (var i = 0; i < tags.length; i++) {
					if (tags[i].name.trim().toLowerCase() == 'source needed') this.src_needed = true;
				}
				if (!this.src_needed) {
					this.info("You have not provided a source. If you know what it is add it to the source field, otherwise consider tagging this video as 'source needed' so others know to search for one.");
				} else {
					this.el.info.css('display', 'none');
				}
			} else {
				this.el.info.css('display', 'none');
			}
			if (tags.length == 0) return this.notify('You need at least one tag.');
			if (tags.length == 1 && tags[0].name.trim().toLowerCase() == 'music') return this.notify("'music' is implied. Tags should be more specific than that. Do you perhaps know who the artist is?");
			this.is_ready = true;
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
			this.is_ready = false;
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
	}
  
	$('#new_tab_button').on('click', function() {
		new Uploader();
	});
	
  return Uploader;
})();
