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

  has_one :comment_thread, as: :owner, dependent: :destroy

  has_many :album_items, dependent: :destroy
  has_many :albums, through: :album_items
  has_many :video_genres, dependent: :destroy
  has_many :tags, through: :video_genres
  has_many :votes, dependent: :destroy
  has_many :tag_histories, dependent: :destroy

  scope :listable, -> { where(hidden: false, duplicate_id: 0) }
  scope :finder, -> { listable.includes(:tags) }
  scope :popular, -> { finder.order(:heat).reverse_order.limit(4) }
  
  scope :random, ->(limit) {
    selection = pluck(:id)
    return { ids: [], videos: Video.none } if selection.blank?

    selected = selection.length < limit ? selection : selection.sample(limit)

    {
      ids: selected,
      videos: finder.where("#{self.table_name}.id IN (?)", selected)
    }
  }

  document_type 'video'
  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :title, analyzer: 'english', index_options: 'offsets'
      indexes :source, analyzer: 'english', index_options: 'offsets'
      indexes :description, analyzer: 'english', index_options: 'offsets'
      indexes :audio_only, type: 'boolean'
      indexes :user_id, type: 'integer'
      indexes :length, type: 'integer'
      indexes :score, type: 'integer'
      indexes :created_at, type: 'date'
      indexes :updated_at, type: 'date'
      indexes :hidden, type: 'boolean'
      indexes :tags, type: 'keyword'
      indexes :likes, type: 'keyword'
      indexes :dislikes, type: 'keyword'
    end
  end

  def as_indexed_json(_options = {})
    json = as_json(only: %w[title description user_id source audio_only length score created_at updated_at hidden])
    json["tags"] = tags.pluck(:name)
    json["likes"] = votes.up.pluck(:user_id)
    json["dislikes"] = votes.down.pluck(:user_id)
    json
  end

  def transfer_to(user)
    self.user = user
    self.save
    self.update_index(defer: false)
  end

  def video_path(root = nil)
    file_path("source#{video.file || '.mp4'}", root)
  end

  def webm_path(root = nil)
    file_path('video.webm', root)
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

  def set_file(media)
    if file
      del_file(video_path.to_s)
      del_file(webm_path.to_s)
    end

    ext = File.extname(media.original_filename)
    if ext == ''
      ext = Mimes.ext(media.content_type)
    end

    self.file = ext
    self.mime = media.content_type

    data = media.read
    hash = Ffmpeg.compute_checksum(data)
    
    if hash != checksum
      self.checksum = hash
    end
    self.video = data
  end

  def realise_checksum
    if (checksum.nil? || checksum.blank?) && has_file(video_path)
      self.checksum = Ffmpeg.compute_checksum(File.read(video_path))
      self.save
    end

    return checksum
  end

  def video=(data)
    store_file(video_path, data)
    generate_webm
  end

  def file_size
    return 0 if !File.exist?(video_path)
    File.size(video_path).to_f / 2**20
  end

  def generate_webm
    if audio_only
      set_status(true)
      return "Completed"
    end

    set_status(nil)

    begin
      ProcessVideoJob.perform_later(id)
    rescue Exception => e
      return "Error: Could not schedule action."
    end

    "Processing Scheduled"
  end

  def set_status(status)
    return if processed == status
    self.processed = status
    self.save
  end

  def processing
    Ffmpeg.locked?(video_path)
  end

  def set_thumbnail(cover = nil, time = nil)
    self.uncache
    self.remove_cover_files

    if save_file(cover_path, cover, 'image/')
      Ffmpeg.extract_tiny_thumb_from_existing(cover_path, tiny_cover_path)
    elsif !audio_only
      time = time ? time.to_f : get_duration.to_f / 2
      Ffmpeg.extract_thumbnail(video_path, cover_path, tiny_cover_path, time)
    end
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
    if (hidden && (!user || user_id != user.id)) || is_spoilered_by(user)
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
    "/#{id}-#{safe_title}"
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

  def widget_header(time, resume, embed, album)
    {
      aspect: aspect,
      source: CGI::escape(widget_parameters(time, resume, embed, album).to_json)
    }
  end

  def aspect
    return 1 if audio_only
    return 1 if get_height == 0

    get_width.to_f / get_height.to_f
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

  def get_duration
    return 0 if hidden
    return compute_length if self.length.nil? || self.length == 0
    self.length
  end

  def get_width
    return 1 if audio_only
    if self.width.nil?
      compute_dimensions
    end
    self.width
  end

  def get_height
    return 1 if self.audio_only
    if self.height.nil?
      compute_dimensions
    end
    self.height
  end

  def set_description(text)
    self.description = text
    text = Comment.parse_bbc_with_replies_and_mentions(text, comment_thread)
    self.html_description = text[:html]
    Comment.send_mentions(text[:mentions], comment_thread, get_title, ref)
    self
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

  protected
  def remove_assets
    del_file(video_path)
    del_file(webm_path)
    self.remove_cover_files
    Tag.where('id IN (?) AND video_count > 0', tags.pluck(:id)).update_all('video_count = video_count - 1')
  end

  def move_assets(from, to)
    rename_file(video_path(from), video_path(to))
    rename_file(webm_path(from), webm_path(to))
    rename_file(cover_path(from), cover_path(to))
    rename_file(tiny_cover_path(from), tiny_cover_path(to))
  end

  private
  def compute_length
    if !file || !has_file(video_path)
      return 0
    end

    self.length = Ffmpeg.get_video_length(video_path)
    self.save
    self.length
  end

  def compute_dimensions
    if !file || !has_file(video_path)
      return
    end

    self.width = Ffmpeg.get_video_width(video_path)
    self.height = Ffmpeg.get_video_height(video_path)
    self.save
  end
end
