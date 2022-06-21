require 'elasticsearch/model'
require 'projectvinyl/web/youtube'

class Video < ApplicationRecord
  include Elasticsearch::Model
  include Indexable, Uncachable, Reportable, Taggable, Statable,
          Periodic, WithFiles, Duplicateable, Unlistable, Likeable,
          Indirected, Heated, Titled

  DEFAULT_ASPECT = 16.to_f/9.to_f

  has_one :comment_thread, as: :owner, dependent: :destroy

  belongs_to :user

  has_many :album_items, dependent: :destroy
  has_many :albums, through: :album_items
  has_many :favouriters, through: :albums, class_name: 'User', source: :users, foreign_key: "star_id"
  has_many :video_genres, dependent: :destroy
  has_many :video_chapters, dependent: :destroy
  has_many :tags, through: :video_genres
  has_many :external_sources

  has_many :artist_tags, ->{ where(namespace: 'artist') }, through: :video_genres, source: :tag, class_name: 'Tag'
  has_many :rating_tags, ->{ where(namespace: 'rating') }, through: :video_genres, source: :tag, class_name: 'Tag'

  has_many :video_visits, dependent: :destroy
  has_many :visits, through: :video_visits, source: :ahoy_visit

  has_many :votes, dependent: :destroy
  has_many :tag_histories, dependent: :destroy

  asset_root :stream
  has_asset :video, :video_file_name, group: :media
  has_asset :audio, 'audio.mp3', group: :media
  has_asset :webm, 'video.webm', group: :media
  has_asset :mpeg, 'video.mp4', group: :media
  has_asset :frames, 'frames', group: :media
  has_asset :cover, 'cover.png', cache_bust: true, group: :cover_files
  has_asset :tiny_cover, 'thumb.png', cache_bust: true, group: :cover_files

  tag_relation :video_genres
  after_save :dispatch_mentions, if: :saved_change_to_description?
  after_save :validate_source, if: :saved_change_to_source?
  after_save :validate_hide_state, if: :saved_change_to_hidden?

  scope :unmerged, -> { where(duplicate_id: 0) }
  scope :listable, -> { where(hidden: false).unmerged }
  scope :for_thumbnails, ->(current_user) { includes(:user).with_tags.with_likes(current_user) }

  document_type 'video'
  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :title, type: 'keyword'
      indexes :source, type: 'keyword'
      indexes :description, type: 'keyword'
      indexes :audio_only, type: 'boolean'
      indexes :mime, type: 'keyword'
      indexes :featured, type: 'boolean'
      indexes :user_id, type: 'integer'
      indexes :length, type: 'integer'
      indexes :width, type: 'integer'
      indexes :height, type: 'integer'
      indexes :score, type: 'integer'
      indexes :size, type: 'integer'
      indexes :heat, type: 'float'
      indexes :boosted, type: 'float'
      indexes :wilson_lower_bound, type: 'float'
      indexes :created_at, type: 'date'
      indexes :updated_at, type: 'date'
      indexes :hidden, type: 'boolean'
      indexes :listing, type: 'integer'
      indexes :duplicate_id, type: 'integer'
      indexes :tags, type: 'keyword'
      indexes :albums, type: 'keyword'
      indexes :likes, type: 'keyword'
      indexes :dislikes, type: 'keyword'
    end
  end

  def as_indexed_json(_options = {})
    read_media_attributes

    json = as_json(only: %w[user_id audio_only heat mime length width height score created_at updated_at hidden listing featured duplicate_id])
    json['title'] = title.downcase
    json['description'] = description.downcase
    json['source'] = source.downcase
    json['tags'] = tags.pluck(:name)
    json['likes'] = votes.up.pluck(:user_id)
    json['albums'] = album_items.pluck(:album_id)
    json['dislikes'] = votes.down.pluck(:user_id)
    json['wilson_lower_bound'] = wilson_lower_bound
    json['size'] = file_size
    json['boosted'] =  boosted_at.to_f / 1.day
    json['heat'] = heat

    json
  end

  def transfer_to(user)
    self.user = user
    self.save
    self.update_index(defer: false)
  end
  
  def publish
    self.draft = false
    self.hidden = false

    return if listing != 0
    artist_tag = user.tag
    return if !artist_tag

    Notification.notify_receivers(artist_tag.subscribers.pluck(:id), comment_thread, "#{user.username} has just uploaded a new video.", link)
  end

  def upload_media(media, checksum)
    self.remove_media if file
    self.file = Mimes.media_ext(media)
    self.mime = media.content_type
    self.audio_only = self.mime.include?('audio/')
    store_file(video_path, checksum[:data])
    self.checksum = checksum[:value]
    self.realise_checksum if checksum.nil?
  end

  def realise_checksum
    if (checksum.nil? || checksum.blank?) && has_video?
      self.checksum = Ffmpeg.compute_checksum(File.read(video_path))
      self.save
    end

    return checksum
  end

  def file_size
    return 0 if !File.exist?(video_path)
    File.size(video_path).to_f / 2**20
  end

  def set_status(status)
    return if processed == status
    self.processed = status
    self.save
  end

  def processing
    Ffmpeg.locked?(video_path)
  end

  def self.thumb_for(video, user, filter)
    video ? video.tiny_thumb(user, filter) : '/images/default-cover-g.png'
  end

  def thumb
    hidden ? '/images/default-cover-g.png' : cover
  end

  def tiny_thumb(user, filter)
    return '/images/default-cover-small-g.png' if (hidden && (!user || user_id != user.id))
    return filter.spoiler_image(self, '/images/default-cover-small-g.png') if filter.video_spoilered?(self)
    tiny_cover
  end

  def link
    "/#{id}"
  end

  def ref
    "/videos/#{id}"
  end

  def mix_string(user)
    result = tags.select do |t|
      !(user && (user.hides?(t.id) || user.spoilers?(t.id))) && t.video_count > 1
    end
    result.map(&:name).sort.join(' | ')
  end

  def json
    {
      id: id,
      title: title,
      description: description,
      tags: tag_string,
      uploader: {
        id: user.id,
        username: user.username
      }
    }
  end

  def widget_parameters(time, resume, embed, album)
    {
        title: title,
        time: time,
        framerate: framerate,
        duration: duration,
        resume: resume,
        path: WithFiles.storage_path(created_at),
        type: audio_only ? 'audio' : 'video',
        id: id,
        mime: [file, mime],
        embedded: embed,
        autoplay: !album.nil?,
        chapters: video_chapters.order(:timestamp).to_jsons
      }
  end

  def thumb_picker_header
    {
      tab: :thumbpick,
      pending: 1,
      source: CGI::escape(widget_parameters(0, false, false, nil).to_json).gsub('+', '%20')
    }
  end

  def widget_header(time, resume, embed, album)
    {
      source: CGI::escape(widget_parameters(time, resume, embed, album).to_json).gsub('+', '%20')
    }
  end

  def aspect
    w = (width || 0).to_f
    h = (height || 0).to_f

    return DEFAULT_ASPECT if w == 0 || h == 0

    w / h
  end

  def duration
    return 0 if hidden
    length || 0
  end

  def dimensions
    "#{width || 0}x#{height || 0}"
  end

  def report(sender_id, params)
    @report = params[:report]
    Report.generate_report(
      reportable: self,
      first: @report[:first],
      source: @report[:source] || @report[:target],
      content_type_unrelated: @report[:content_type_unrelated] == '1',
      content_type_offensive: @report[:content_type_offensive] == '1',
      content_type_disturbing: @report[:content_type_disturbing] == '1',
      content_type_explicit: @report[:content_type_explicit] == '1',
      copyright_holder: @report[:copyright_holder],
      subject: @report[:subject],
      other: @report[:note] || @report[:other],
      name: @report[:name],
      user_id: sender_id
    )
  end

  def read_media_attributes
    self.framerate, self.width, self.height = [1,1,1]

    self.length = Ffprobe.length(video_path) if has_video?
    self.framerate = Ffprobe.framerate(video_path) if !audio_only && has_video?

    path = audio_only && has_cover? ? cover_path : video_path

    self.width, self.height = Ffprobe.dimensions(path) if File.exist?(path)
  end

  def dispatch_mentions
    if !(sender = comment_thread)
      sender = CommentThread.new({
        user_id: user_id,
        owner: self,
        title: title
      })
    end
    text = Comment.parse_bbc_with_replies_and_mentions(description, sender)
    Comment.send_mentions(text[:mentions], sender, title, ref)

    video_chapters.destroy_all
    video_chapters.create(text[:chapters])
  end

  private
  def video_file_name(key)
    "source#{file || '.mp4'}"
  end

  def validate_source
    self.source = PathHelper.clean_url(source)
  end

  def validate_hide_state
    update_file_locations
    update_index
  end
end
