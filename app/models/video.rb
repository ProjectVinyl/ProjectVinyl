require 'elasticsearch/model'
require 'projectvinyl/web/youtube'

class Video < ApplicationRecord
  include Elasticsearch::Model
  include Indexable
  include Uncachable
  include WithFiles
  include Taggable
  include Periodic
  include Reportable
  include Indirected
  include Statable
  include Heated
  include Duplicateable
  include Likeable
  include Unlistable

  DEFAULT_ASPECT = 16.to_f/9.to_f

  has_one :comment_thread, as: :owner, dependent: :destroy

  belongs_to :user

  has_many :album_items, dependent: :destroy
  has_many :albums, through: :album_items
  has_many :video_genres, dependent: :destroy
  has_many :tags, through: :video_genres
  has_many :votes, dependent: :destroy
  has_many :tag_histories, dependent: :destroy

  after_save :dispatch_mentions, if: :will_save_change_to_description?

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
      indexes :heat, type: 'integer'
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
    read_media_attributes!

    json = as_json(only: %w[user_id audio_only heat mime length width height score created_at updated_at hidden listing featured duplicate_id])
    json['title'] = title.downcase
    json['description'] = description.downcase
    json['source'] = source.downcase
    json['tags'] = tags.pluck(:name)
    json['likes'] = votes.up.pluck(:user_id)
    json['albums'] = album_items.pluck(:album_id)
    json['dislikes'] = votes.down.pluck(:user_id)
    json['size'] = file_size
    json['heat'] = heat

    json
  end

  def transfer_to(user)
    self.user = user
    self.save
    self.update_index(defer: false)
  end

  def audio_path(root = nil)
    file_path('audio.mp3', root)
  end
  
  def video_path(root = nil)
    file_path("source#{file || '.mp4'}", root)
  end

  def webm_path(root = nil)
    file_path('video.webm', root)
  end

  def mpeg_path(root = nil)
    file_path('video.mp4', root)
  end

  def webm_url
    public_url('video.webm')
  end

  def set_hidden(val)
    if hidden != val
      self.hidden = val
      update_file_locations
      update_index(defer: false)
    end
  end

  def cover_path(root = nil)
    file_path('cover.png', root)
  end

  def tiny_cover_path(root = nil)
    file_path('thumb.png', root)
  end

  def media=(media)
    self.remove_media if file
    self.file = Mimes.media_ext(media)
    self.mime = media.content_type
    self.video = media.read

    EncodeFilesJob.queue_video(self)
  end

  def video=(data)
    self.checksum = nil
    store_file(video_path, data)
    self.realise_checksum
  end

  def realise_checksum
    if (checksum.nil? || checksum.blank?) && has_file(video_path)
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

  def self.thumb_for(video, user)
    video ? video.tiny_thumb(user) : '/images/default-cover-g.png'
  end

  def thumb
    hidden ? '/images/default-cover.png' : direct_thumb
  end

  def direct_thumb
    cache_bust(public_url('cover.png'))
  end

  def tiny_thumb(user)
    if (hidden && (!user || user_id != user.id)) || spoilered_by?(user)
      return '/images/default-cover-small.png'
    end
    cache_bust(public_url('thumb.png'))
  end
  
  def model_path
    'stream'
  end

  # Overrides Taggable
  def drop_tags(ids)
    Tag.where('id IN (?) AND video_count > 0', ids).update_all('video_count = video_count - 1')
    VideoGenre.where('video_id = ? AND tag_id IN (?)', id, ids).delete_all
  end

  def pick_up_tags(ids)
    Tag.where('id IN (?)', ids).update_all('video_count = video_count + 1')
    self.video_genres
  end
  # #################

  def link
    "/#{id}"
  end

  def ref
    "/videos/#{id}"
  end

  def artists_string
    Tag.tag_string(tags.where(tag_type_id: 1))
  end

  def artists
    self.tags.where(tag_type_id: 1).order(:video_count).reverse_order.limit(3).each do |tag|
      tag = tag.alias if tag.alias_id
      yield(tag.user ? tag.user.username : tag.identifier)
    end
  end

  def mix_string(user)
    result = tags.select do |t|
      !(user && (user.hides([t.id]) || user.spoilers([t.id]))) && t.video_count > 1
    end
    result.map(&:name).sort.join(' | ')
  end

  def set_source(s)
    self.source = PathHelper.clean_url(s)
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
        title: get_title,
        time: time,
        resume: resume,
        path: WithFiles.storage_path(created_at),
        type: audio_only ? 'audio' : 'video',
        id: id,
        mime: [file, mime],
        embedded: embed,
        autoplay: !album.nil?
      }
  end

  def thumb_picker_header
    {
      tab: :thumbpick,
      pending: 1,
      source: CGI::escape(widget_parameters(0, false, false, nil).to_json)
    }
  end

  def widget_header(time, resume, embed, album)
    {
      source: CGI::escape(widget_parameters(time, resume, embed, album).to_json)
    }
  end

  def aspect
    w = (width || 0).to_f
    h = (height || 0).to_f

    return DEFAULT_ASPECT if w == 0 || h == 0

    w / h
  end

  def get_title
    title || "Untitled Video"
  end

  def set_title(title)
    title = StringsHelper.check_and_trunk(title, get_title)
    self.title = title
    self.safe_title = PathHelper.url_safe(title)
    if comment_thread_id
      comment_thread.title = title
      comment_thread.save
    end
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

  def remove_cover_files
    del_file(cover_path)
    del_file(tiny_cover_path)
  end

  def remove_media
    del_file(video_path)
    del_file(mpeg_path)
    del_file(webm_path)
    del_file(audio_path)
  end

  def read_media_attributes!

    path = audio_only && has_file(cover_path) ? cover_path : video_path

    self.length = Ffmpeg.get_video_length(video_path) if has_file(video_path)

    self.width, self.height = [1,1]
    self.width, self.height = Ffmpeg.get_dimensions(path) if has_file(path)
    self.save
  end

  protected

  def remove_assets
    self.remove_media
    self.remove_cover_files
    Tag.where('id IN (?) AND video_count > 0', tags.pluck(:id)).update_all('video_count = video_count - 1')
  end

  def move_assets(from, to)
    rename_file(video_path(from), video_path(to))
    rename_file(webm_path(from), webm_path(to))
    rename_file(mpeg_path(from), mpeg_path(to))
    rename_file(audio_path(from), audio_path(to))
    rename_file(cover_path(from), cover_path(to))
    rename_file(tiny_cover_path(from), tiny_cover_path(to))
  end

  private
  def dispatch_mentions
    if !(sender = comment_thread)
      sender = CommentThread.new({
        user_id: user_id,
        owner: self,
        title: get_title
      })
    end
    text = Comment.parse_bbc_with_replies_and_mentions(description, sender)
    Comment.send_mentions(text[:mentions], sender, get_title, ref)
  end
end
