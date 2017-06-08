require 'elasticsearch/model'

class Video < ActiveRecord::Base
  include Elasticsearch::Model
  include Indexable
  include Uncachable

  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"

  has_one :comment_thread, as: :owner, dependent: :destroy

  has_many :album_items, dependent: :destroy
  has_many :albums, through: :album_items
  has_many :video_genres, dependent: :destroy
  has_many :tags, through: :video_genres
  has_many :votes, dependent: :destroy

  scope :listable, -> { where(hidden: false, duplicate_id: 0) }

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

  def self.finder
    Video.includes(:tags).listable
  end

  def self.popular
    Video.finder.order(:heat).reverse_order.limit(4)
  end

  def self.random_videos(selection, limit)
    selection = selection.pluck(:id)
    return { ids: [], videos: [] } if selection.blank?
    if selection.length < limit
      selected = selection
    else
      selected = selection.sample(limit)
    end
    {
      ids: selected,
      videos: Video.finder.where('id IN (?)', selected)
    }
  end

  def self.clean_url(s)
    return '' if s.blank?
    return 'https:' + s if s.index('http:') != 0 && s.index('https:') != 0
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
    VideoProcessor.queue.count
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
    total_vid = Video.where('audio_only = false').count
    report.other << "<br>Missing video files: " + (total - sources.length).to_s
    report.other << "<br>Missing webm files : " + (total_vid - webms.length).to_s
    report.save
    Video.where('id NOT IN (?) AND audio_only = false AND processed = true AND NOT file = ".webm"', webms).update_all(processed: nil)
    Video.where('id NOT IN (?) AND hidden = false AND NOT file = ".webm"', sources).update_all(hidden: true)
    Video.reset_hidden_flags

    #  damaged = []
    #  Video.where('id IN (?)', webms).find_each do |video|
    #    if Ffmpeg.get_video_length(video.webm_path) != Ffmpeg.get_video_length(video.video_path)
    #      damaged << video.id
    #      File.rename(video.webm_path, location.join('damaged', video.id.to_s + ".webm"))
    #    end
    #  end
    #  if damaged.length > 0
    #    report.other << "<br>Dropped " + damaged.length.to_s + " Damaged webm files"
    #    report.save
    #    Video.where('id IN (?)', damaged).update_all(processed: nil)
    #  end
    if (total - sources.length) > 0
      report.other << "<br><br>Damaged videos have been removed from public listings until they can be repaired."
      report.save
    end
  end

  def user
    self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end

  def user=(user)
    self.direct_user = user
  end

  def transfer_to(user)
    self.user = user
    self.save
    self.update_index(defer: false)
  end

  def remove_self
    del_file(self.video_path)
    del_file(self.webm_path)
    del_file(self.cover_path.to_s + ".png")
    del_file(self.cover_path.to_s + "-small.png")
    Tag.where('id IN (?) AND video_count > 0', self.tags.pluck(:id)).update_all('video_count = video_count - 1')
    TagHistory.destroy_for(self)
    self.destroy
  end

  def video_path
    Video.video_file_path(self.hidden ? 'private' : 'public', self)
  end

  def webm_path
    Video.webm_file_path(self.hidden ? 'private' : 'public', self)
  end

  def self.video_file_path(root, video)
    Rails.root.join(root, 'stream', video.id.to_s + (video.file || ".mp4"))
  end

  def self.webm_file_path(root, video)
    Rails.root.join(root, 'stream', video.id.to_s + '.webm')
  end

  def self.reset_hidden_flags
    items = Video.where(hidden: true).find_each(&:update_file_locations)
    items.length
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
      move_files('public', 'private')
    else
      move_files('private', 'public')
    end
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
      VideoProcessor.enqueue(self)
      "Processing Scheduled"
    else
      if !self.processed
        self.processed = true
        self.save
      end
      "Completed"
    end
  end

  def generate_webm_sync
    if !self.audio_only
      self.processed = false
      self.save
      Ffmpeg.produce_webm(self.video_path) do ||
        self.processed = true
        self.save
      end
    else
      self.processed = true
      self.save
      "Completed"
    end
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
      del_file(self.cover_path.to_s + ".png")
      del_file(self.cover_path.to_s + "-small.png")
      File.open(self.cover_path.to_s + '.png', 'wb') do |file|
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
    del_file(self.cover_path.to_s + ".png")
    del_file(self.cover_path.to_s + "-small.png")
    Ffmpeg.extract_thumbnail(self.video_path, self.cover_path, time)
  end

  def self.thumb_for(video, user)
    video ? video.tiny_thumb(user) : '/images/default-cover-g.png'
  end

  def thumb
    return '/images/default-cover.png' if self.hidden
    self.cache_bust('/cover/' + self.id.to_s + '.png')
  end

  def tiny_thumb(user)
    if (self.hidden && (!user || self.user_id != user.id)) || self.is_spoilered_by(user)
      return '/images/default-cover-small.png'
    end
    self.cache_bust('/cover/' + self.id.to_s + '-small.png')
  end

  def drop_tags(ids)
    Tag.where('id IN (?) AND video_count > 0', ids).update_all('video_count = video_count - 1')
    VideoGenre.where('video_id = ? AND tag_id IN (?)', self.id, ids).delete_all
  end

  def pick_up_tags(ids)
    Tag.where('id IN (?)', ids).update_all('video_count = video_count + 1')
    self.video_genres
  end

  def tags_changed
    self.update_index(defer: false)
  end

  def tag_string
    Tag.tag_string(self.tags)
  end

  def link
    '/' + self.id.to_s + '-' + self.safe_title.to_s
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
    incr = incr.to_i
    vote = user.votes.where(video_id: self.id).first
    if vote.nil?
      vote = user.votes.create(video_id: self.id, negative: false)
    else
      if incr < 0
        vote.destroy
      elsif incr > 0
        self.downvotes = self.downvotes - 1 if vote.negative
        vote.negative = false
        vote.save
      end
    end
    self.upvotes = computeCount(incr, self.upvotes)
    compute_score
    self.upvotes
  end

  def downvote(user, incr)
    incr = incr.to_i
    vote = user.votes.where(video_id: self.id).first
    if vote.nil?
      vote = user.votes.create(video_id: self.id, negative: true)
    else
      if incr < 0
        vote.destroy
      elsif incr > 0
        self.upvotes = self.upvotes - 1 if !vote.negative
        vote.negative = true
        vote.save
      end
    end
    self.downvotes = computeCount(incr, self.downvotes)
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
      src = 'https://www.youtube.com/watch?v=' + Youtube.video_id(src)
      meta = Youtube.get(src, title: tit, description: dsc, artist: tgs)
      self.set_title(meta[:title]) if tit && meta[:title]
      if dsc && meta[:description]
        self.set_description(meta[:description][:bbc])
      end
      if tgs && meta[:artist]
        if (artist_tag = Tag.sanitize_name(meta[:artist])) && !artist_tag.empty?
          artist_tag = Tag.add_tag('artist:' + artist_tag, self)
          if !artist_tag.nil?
            TagHistory.record_changes_auto(self, artist_tag[0], artist_tag[1])
          end
        end
      end
      self.set_source(src)
      TagHistory.record_source_change_auto(self, src)
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
    return user.hides(@tag_ids || (@tag_ids = self.tags.map(&:id))) if user
    false
  end

  def is_spoilered_by(user)
    return user.spoilers(@tag_ids || (@tag_ids = self.tags.map(&:id))) if user
    false
  end

  def is_upvoted_by(user)
    if user
      return user.votes.where(video_id: self.id, negative: false).count > 0
    end
    false
  end

  def is_downvoted_by(user)
    return user.votes.where(video_id: self.id, negative: true).count > 0 if user
    false
  end

  def is_starred_by(user)
    return user.album_items.where(video_id: self.id).count > 0 if user
    false
  end

  def get_title
    self.title || "Untitled Video"
  end

  def set_title(title)
    title = ApplicationHelper.check_and_trunk(title, self.title || "Untitled Video")
    title = ApplicationHelper.demotify(title)
    self.title = title
    self.safe_title = ApplicationHelper.url_safe(title)
    if self.comment_thread_id
      self.comment_thread.title = title
      self.comment_thread.save
    end
  end

  def set_description(text)
    text = ApplicationHelper.demotify(text)
    self.description = text
    text = Comment.extract_mentions(text, self.comment_thread, self.getTitle, '/view/' + self.id.to_s)
    self.html_description = ApplicationHelper.emotify(text)
    self
  end

  def get_duration
    return 0 if self.hidden
    return compute_length if self.length.nil? || self.empty?
    self.length
  end

  def period
    return "Today" if self.created_at > Time.zone.now.beginning_of_day
    if self.created_at > Time.zone.now.yesterday.beginning_of_day
      return "Yesterday"
    end
    if self.created_at > Time.zone.now.beginning_of_week
      return "Earlier this Week"
    end
    if self.created_at > (Time.zone.now.beginning_of_week - 1.week)
      return "Last Week"
    end
    if self.created_at > (Time.zone.now.beginning_of_week - 2.weeks)
      return "Two Weeks Ago"
    end
    if self.created_at > Time.zone.now.beginning_of_month
      return "Earlier this Month"
    end
    self.created_at.strftime('%B %Y')
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
    Notification.notify_recievers_without_delete(recievers, self.comment_thread,
                                                 user.username + " has merged <b>" + self.title + "</b> into <b>" + other.title + "</b>",
                                                 other.comment_thread.location)
    self.save
    self
  end

  def unmerge
    self.save if self.do_unmerge
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

  def del_file(path)
    File.delete(path) if File.exist?(path)
  end

  private

  def move_files(from, to)
    rename_file(Video.video_file_path(from, self), Video.video_file_path(to, self))
    rename_file(Video.webm_file_path(from, self), Video.webm_file_path(to, self))
  end

  def rename_file(from, to)
    File.rename(from, to) if File.exist?(from)
  end

  def compute_length
    if self.file
      self.length = Ffmpeg.get_video_length(self.video_path)
      save
      return self.length
    end
    0
  end

  def compute_score
    self.score = self.upvotes - self.downvotes
    self.update_index(defer: false)
    self.compute_hotness.save
  end

  def compute_count(incr, count)
    count = 0 if count.nil? || count.nil?
    return count - 1 if incr < 0 && count > 0
    return count + 1 if incr > 0
    count
  end
end
