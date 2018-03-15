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
  
  has_one :comment_thread, as: :owner, dependent: :destroy

  has_many :album_items, dependent: :destroy
  has_many :albums, through: :album_items
  has_many :video_genres, dependent: :destroy
  has_many :tags, through: :video_genres
  has_many :votes, dependent: :destroy
  
  scope :listable, -> { where(hidden: false, duplicate_id: 0) }
  scope :finder, -> { listable.includes(:tags) }
  scope :popular, -> { finder.order(:heat).reverse_order.limit(4) }
  scope :with_likes, ->(user) {
    if !user.nil? 
      return joins("LEFT JOIN `votes` ON `votes`.video_id = `videos`.id AND `votes`.user_id = #{user.id}")
        .select('`videos`.*, `votes`.user_id AS is_liked_flag, `votes`.negative AS is_like_negative_flag')
    end
  }
  scope :random, ->(limit) {
    selection = pluck(:id)
    return { ids: [], videos: Video.none } if selection.blank?
    
    selected = selection.length < limit ? selection : selection.sample(limit)
    
    {
      ids: selected,
      videos: finder.where("`#{self.table_name}`.id IN (?)", selected)
    }
  }
  
  def is_liked
    (respond_to? :is_liked_flag) && is_liked_flag
  end
  
  def is_like_negative
    (respond_to? :is_like_negative_flag) && is_like_negative_flag
  end
  
  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'true' do
      indexes :title
      indexes :source
      indexes :audio_only, type: 'boolean'
      indexes :user_id, type: 'integer'
      indexes :length, type: 'integer'
      indexes :score, type: 'integer'
      indexes :created_at, type: 'date'
      indexes :updated_at, type: 'date'
      indexes :hidden, type: 'boolean'
    end
    mappings dynamic: 'false' do
      indexes :tags, type: 'keyword'
      indexes :likes, type: 'keyword'
      indexes :dislikes, type: 'keyword'
    end
  end

  def as_indexed_json(_options = {})
    json = as_json(only: %w[title user_id source audio_only length score created_at updated_at hidden])
    json["tags"] = self.tags.pluck(:name)
    json["likes"] = self.votes.up.pluck(:user_id)
    json["dislikes"] = self.votes.down.pluck(:user_id)
    json
  end
  
  def self.clean_url(s)
    if s.blank?
      return ''
    end
    
    if s.index('http:') != 0 && s.index('https:') != 0
      return "https:#{s}"
    end
    
    s
  end
	
  def self.ensure_uniq(data)
    if data
      hash = Ffmpeg.compute_checksum(data)
      if Video.where(checksum: hash).count == 0
        return { valid: true, value: hash }
      end
    end
    { valid: false }
  end
	
  def self.rebuild_queue
    webms = []
    location = Rails.root.join('public', 'stream')
    Dir.entries(location.to_s).each do |name|
      next unless name.index('.')
      split = name.split('.')
      if (id = split[0].to_i) && id > 0
        webms << id if split[1] == 'webm'
      end
    end
    workings = []
    location = Rails.root.join('encoding')
    Dir.entries(location.to_s).each do |name|
      next unless name.index('.')
      split = name.split('.')
      next unless (id = split[0].to_i) && id > 0
      if split[1] == 'webm'
        webms << id
        workings << id
      end
    end
    Video.where('id NOT IN (?) AND audio_only = false', webms).update_all(processed: nil)
    Video.where('id IN (?)', workings).update_all(processed: false)
    Video.where(processed: nil, hidden: false).count # return count
  end

  def self.verify_integrity(report)
    webms = []
    sources = []
    
    location = Rails.root.join('public', 'stream')
    Dir.entries(location.to_s).each do |name|
      next unless name.index('.')
      split = name.split('.')
      if (id = split[0].to_i) && id > 0
        if split[1] == 'webm'
          webms << id
        else
          sources << id
        end
      end
    end
    total = Video.all.count
    total_vid = Video.where(audio_only: false).count
    
    report.write("Missing video files: #{total - sources.length}")
    report.write("Missing webm files : #{total_vid - webms.length}")
    
    Video.where('id NOT IN (?) AND audio_only = false AND processed = true AND NOT file = ".webm"', webms).update_all(processed: nil)
    Video.where('id NOT IN (?) AND hidden = false AND NOT file = ".webm"', sources).update_all(hidden: true)
    Video.reset_hidden_flags
    
    if (total - sources.length) > 0
      report.write("<br>Damaged videos have been removed from public listings until they can be repaired.")
    end
  end
  
  def transfer_to(user)
    self.user = user
    self.save
    self.update_index(defer: false)
  end
  
  def remove_self
    del_file(self.video_path)
    del_file(self.webm_path)
    self.remove_cover_files
    Tag.where('id IN (?) AND video_count > 0', self.tags.pluck(:id)).update_all('video_count = video_count - 1')
    TagHistory.destroy_for(self)
    self.destroy
  end
  
  def remove_cover_files
    del_file("#{self.cover_path}.png")
    del_file("#{self.cover_path}-small.png")
  end
  
  def video_path
    Video.video_file_path(storage_root, self)
  end

  def webm_path
    Video.webm_file_path(storage_root, self)
  end

  def self.video_file_path(root, video)
    Rails.root.join(root, 'stream', "#{video.id}#{video.file || '.mp4'}")
  end

  def self.webm_file_path(root, video)
    Rails.root.join(root, 'stream', "#{video.id}.webm")
  end

  def self.reset_hidden_flags
    Video.where(hidden: true).find_each(&:update_file_locations)
    Video.where(hidden: true).count # return count
  end

  def set_hidden(val)
    if self.hidden != val
      self.hidden = val
      self.update_file_locations
      self.update_index(defer: false)
    end
  end

  def update_file_locations
    if self.hidden
      return move_files('public', 'private')
    end
    
    move_files('private', 'public')
  end

  def cover_path
    Rails.root.join('public', 'cover', self.id.to_s)
  end

  def set_file(media)
    if self.file
      del_file(self.video_path.to_s)
      del_file(self.webm_path.to_s)
    end
    ext = File.extname(media.original_filename)
    ext = Mimes.ext(media.content_type) if ext == ''
    self.file = ext
    self.mime = media.content_type
    data = media.read
    hash = Ffmpeg.compute_checksum(data)
    self.checksum = hash if hash != self.checksum
    self.save_file(data)
  end

  def save_file(data)
    File.open(self.video_path, 'wb') do |file|
      file.write(data)
      file.flush
    end
    self.generate_webm
  end

  def generate_webm
    if !self.audio_only
      if !self.processed.nil?
        self.processed = nil
        self.save
      end
      ProcessVideoJob.perform_later(self.id)
      
      return "Processing Scheduled"
    end
    
    if !self.processed
      self.processed = true
      self.save
    end
    
    "Completed"
  end

  def generate_webm_sync
    if !self.audio_only
      self.processed = false
      self.save
      return Ffmpeg.produce_webm(self.video_path) do ||
        self.processed = true
        self.save
      end
    end
    
    self.processed = true
    self.save
    "Completed"
  end

  def check_index
    if Ffmpeg.try_unlock?(self.video_path)
      self.processed = true
      self.save
      return true
    end
    false
  end

  def processing
    Ffmpeg.locked?(self.video_path)
  end

  def set_thumbnail(cover)
    self.uncache
    if cover && cover.content_type.include?('image/')
      self.remove_cover_files
      File.open("#{self.cover_path}.png", 'wb') do |file|
        file.write(cover.read)
        file.flush
      end
      Ffmpeg.extract_tiny_thumb_from_existing(self.cover_path)
    elsif !self.audio_only
      Ffmpeg.extract_thumbnail(self.video_path, self.cover_path, self.get_duration.to_f / 2)
    end
  end

  def set_thumbnail_time(time)
    self.uncache
    self.remove_cover_files
    Ffmpeg.extract_thumbnail(self.video_path, self.cover_path, time)
  end
  
  def self.thumb_for(video, user)
    video ? video.tiny_thumb(user) : '/images/default-cover-g.png'
  end

  def thumb
    self.hidden ? '/images/default-cover.png' : self.cache_bust("/cover/#{self.id}.png")
  end

  def tiny_thumb(user)
    if (self.hidden && (!user || self.user_id != user.id)) || self.is_spoilered_by(user)
      return '/images/default-cover-small.png'
    end
    self.cache_bust("/cover/#{self.id}-small.png")
  end
  
  # Overrides Taggable
  def drop_tags(ids)
    Tag.where('id IN (?) AND video_count > 0', ids).update_all('video_count = video_count - 1')
    VideoGenre.where('video_id = ? AND tag_id IN (?)', self.id, ids).delete_all
  end

  def pick_up_tags(ids)
    Tag.where('id IN (?)', ids).update_all('video_count = video_count + 1')
    self.video_genres
  end
  # #################
  
  def link
    "/#{self.id}-#{self.safe_title}"
  end
  
  def ref
    "/videos/#{self.id}"
  end
  
  def artists_string
    Tag.tag_string(self.tags.where(tag_type_id: 1))
  end

  def artists
    self.tags.where(tag_type_id: 1).order(:video_count).reverse_order.limit(3).each do |tag|
      tag = tag.alias if tag.alias_id
      yield(tag.user ? tag.user.username : tag.identifier)
    end
  end

  def get_computed_score
    compute_score if self.score.nil?
    self.score
  end

  def upvote(user, incr)
    Vote.vote(user, self, incr, false)
    compute_score
    self.upvotes
  end

  def downvote(user, incr)
    Vote.vote(user, self, incr, true)
    compute_score
    self.downvotes
  end
  
  def star(user)
    user.stars.toggle(self)
  end

  def mix_string(user)
    result = self.tags.select do |t|
      !(user && (user.hides([t.id]) || user.spoilers([t.id]))) && t.video_count > 1
    end
    result.map(&:name).sort.join(' | ')
  end

  def pull_meta(src, tit, dsc, tgs)
    if src.present?
      src = "https://www.youtube.com/watch?v=#{ProjectVinyl::Web::Youtube.video_id(src)}"
      self.set_source(src)
      
      meta = ProjectVinyl::Web::Youtube.get(src, title: tit, description: dsc, artist: tgs)
      self.set_title(meta[:title]) if tit && meta[:title]
      if dsc && meta[:description]
        self.set_description(meta[:description][:bbc])
      end
      if tgs && meta[:artist]
        if (artist_tag = Tag.sanitize_name(meta[:artist])) && !artist_tag.empty?
          artist_tag = Tag.add_tag('artist:' + artist_tag, self)
          if !artist_tag.nil?
            TagHistory.record_tag_changes(artist_tag[0], artist_tag[1], self.id)
          end
        end
      end
      
      TagHistory.record_source_changes(self)
      self.save
    end
  end

  def set_source(s)
    self.source = Video.clean_url(s)
  end

  def json
    {
      id: self.id,
      title: self.title,
      description: self.description,
      tags: self.tag_string,
      uploader: {
        id: self.user.id,
        username: self.user.username
      }
    }
  end

  def is_hidden_by(user)
    user && user.hides(@tag_ids || (@tag_ids = self.tags.map(&:id)))
  end

  def is_spoilered_by(user)
    user && user.spoilers(@tag_ids || (@tag_ids = self.tags.map(&:id)))
  end
  
  # virtual fields added by .with_likes(user)
  def is_upvoted
    self.is_liked && self.is_like_negative != 1
  end

  def is_downvoted
    self.is_liked && self.is_like_negative != 0
  end
  #
  
  def is_starred_by(user)
    user && user.album_items.where(video_id: self.id).count > 0
  end

  def get_title
    self.title || "Untitled Video"
  end

  def set_title(title)
    title = ApplicationHelper.check_and_trunk(title, get_title)
    self.title = title
    self.safe_title = ApplicationHelper.url_safe(title)
    if self.comment_thread_id
      self.comment_thread.title = title
      self.comment_thread.save
    end
  end
  
  def get_duration
    return 0 if self.hidden
    return compute_length if self.length.nil? || self.length == 0
    self.length
  end
  
  def set_description(text)
    self.description = text
    text = Comment.parse_bbc_with_replies_and_mentions(text, self.comment_thread)
    self.html_description = text[:html]
    Comment.send_mentions(text[:mentions], self.comment_thread, self.get_title, self.ref)
    self
  end
  
  def compute_hotness
    x = self.views || 0
    x += 2 * (self.upvotes || 0)
    x += 2 * (self.downvotes || 0)
    x += 3 * self.comment_thread.comments.count
    basescore = Math.log([x, 1].max)

    n = DateTime.now
    c = self.created_at.to_datetime
    if c < (n - 3.weeks)
      x = ((n - c).to_f / 7) - 1
      basescore *= Math.exp(-8 * x * x)
    end
    self.heat = basescore * 1000
    self
  end

  def merge(user, other)
    self.do_unmerge
    self.duplicate_id = other.id
    AlbumItem.where(video_id: self.id).update_all('video_id = ' + other.id.to_s)
    Comment.where(comment_thread_id: self.comment_thread_id).update_all(comment_thread_id: other.comment_thread_id)
    mytags = Tag.relation_to_ids(self.tags)
    tags = mytags - Tag.relation_to_ids(other.tags)
    tags = tags.uniq
    if !tags.empty?
      Tag.send_pickup_event(other, tags)
      self.drop_tags(mytags)
    end
    recievers = self.comment_thread.comments.pluck(:user_id) | [self.user_id]
    Notification.notify_recievers_without_delete(recievers, self.comment_thread, "#{user.username} has merged <b>#{self.title}</b> into <b>#{other.title}</b>", other.comment_thread.location)
    self.save
    self
  end

  def unmerge
    self.save if self.do_unmerge
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
  
  protected
  def do_unmerge
    if self.duplicate_id
      if other = Video.where(id: self.duplicate_id).first
        Tag.send_pickup_event(self, Tag.relation_to_ids(other.tags))
        AlbumItem.where(video_id: other.id, o_video_id: self.id).update_all('video_id = o_video_id')
        Comment.where(comment_thread_id: other.comment_thread_id, o_comment_thread_id: self.comment_thread_id).update_all('comment_thread_id = o_comment_thread_id')
      end
      self.duplicate_id = 0
      return true
    end
    false
  end
  
  private
  def move_files(from, to)
    rename_file(Video.video_file_path(from, self), Video.video_file_path(to, self))
    rename_file(Video.webm_file_path(from, self), Video.webm_file_path(to, self))
  end
  
  def compute_length
    if !self.file
      return 0
    end
    
    self.length = Ffmpeg.get_video_length(self.video_path)
    self.save
    self.length
  end

  def compute_score
    self.score = self.upvotes - self.downvotes
    self.update_index(defer: false)
    self.compute_hotness.save
  end
end
