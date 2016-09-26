class Video < ActiveRecord::Base
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  
  has_one :comment_thread, as: :owner, dependent: :destroy
  
  has_many :album_items, dependent: :destroy
  has_many :albums, :through => :album_items
  has_many :video_genres, dependent: :destroy
  has_many :tags, :through => :video_genres
  
  def self.Finder
    return Video.includes(:tags).where(hidden: false)
  end
  
  def self.randomVideos(selection, limit)
    selection = selection.pluck(:id)
    if !selection || selection.length == 0
      return []
    end
    if selection.length < limit
      selected = selection
    else
      selected = selection.sample(limit)
    end
    return Video.where('id IN (?)', selected)
  end
  
  def self.ensure_uniq(data)
    if data
      hash = Ffmpeg.compute_checksum(data)
      if Video.where(checksum: hash).count == 0
        return {valid: true, value: hash}
      end
    end
    return {valid: false}
  end
  
  def self.verify_integrity(report)
    webms = []
    sources = []
    location = Rails.root.join('public', 'stream')
    Dir.entries(location.to_s).each do |name|
      if name.index('.')
        split = name.split('.')
        if (id = split[0].to_i) && id > 0
          if split[1] == 'webm'
            webms << id
          else
            sources << id
          end
        end
      end
    end
    total = Video.all.count
    total_vid = Video.where('audio_only = false').count
    report.other << "<br>Missing video files: " + (total - sources.length).to_s
    report.other << "<br>Missing webm files : " + (total_vid - webms.length).to_s
    report.save
    Video.where('id NOT IN (?) AND audio_only = false AND processed = true', webms).update_all(processed: nil)
    Video.where('id NOT IN (?) AND hidden = false', sources).update_all(hidden: true)
    damaged = []
    Video.where('id IN (?)', webms).find_in_batches do |batch|
      batch.each do |video|
        if Ffmpeg.getVideoLength(video.webm_path) != Ffmpeg.getVideoLength(video.video_path)
          damaged << video.id
          File.rename(video.webm_path, location.join('damaged', video.id.to_s + ".webm"))
        end
      end
    end
    if damaged.length > 0
      report.other << "<br>Dropped " + damaged.length.to_s + " Damaged webm files"
      report.save
      Video.where('id IN (?)', damaged).update_all(processed: nil)
    end
    if (total - sources.length) > 0
      report.other << "<br><br>Damaged videos have been removed from public listings until they can be repaired."
      report.save
    end
  end
  
  def user
    return self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end
  
  def user=(user)
    self.direct_user = user
  end
  
  def transferTo(user)
    self.user = user
    self.save
  end
  
  def removeSelf
    delFile(self.video_path)
    delFile(self.webm_path)
    delFile(self.cover_path.to_s + ".png")
    delFile(self.cover_path.to_s + "-small.png")
    Tag.where('id IN (?) AND video_count > 0', self.tags.pluck(:id)).update_all('video_count = video_count - 1')
    self.destroy
  end
  
  def video_path
    return Video.video_file_path(self.hidden ? 'private' : 'public', self)
  end
  
  def webm_path
    return Video.webm_file_path(self.hidden ? 'private' : 'public', self)
  end
  
  def self.video_file_path(root, video)
    return Rails.root.join(root, 'stream', video.id.to_s + (video.file || ".mp4"))
  end
  
  def self.webm_file_path(root, video)
    return Rails.root.join(root, 'stream', video.id.to_s + '.webm')
  end
  
  def set_hidden(val)
    if self.hidden != val
      if self.hidden
        move_files('private', 'public')
      else
        move_files('public', 'private')
      end
      self.hidden = val
    end
  end
    
  def cover_path
    return Rails.root.join('public', 'cover', self.id.to_s)
  end
  
  def setFile(media)
    if self.file
      delFile(self.video_path.to_s)
      delFile(self.webm_path.to_s)
    end
    ext = File.extname(media.original_filename)
    if ext == ''
      ext = Mimes.ext(media.content_type)
    end
    self.file = ext
    self.mime = media.content_type
    data = media.read
    hash = Ffmpeg.compute_checksum(data)
    if hash != self.checksum
      self.checksum = hash
    end
    self.save_file(data)
  end
  
  def save_file(data)
    File.open(self.video_path, 'wb') do |file|
      file.write(data)
      file.flush()
    end
    self.processed = nil
    self.save
  end
  
  def generateWebM
    if !self.audio_only
      self.processed = nil
      self.save
      VideoProcessor.enqueue(self)
      return "Processing Scheduled"
    else
      self.processed = true
      self.save
      return "Completed"
    end
  end
  
  def generateWebM_sync
    if !self.audio_only
      self.processed = false
      self.save
      return Ffmpeg.produceWebM(self.video_path) do ||
        self.processed = true
        self.save
      end
    else
      self.processed = true
      self.save
      return "Completed"
    end
  end
  
  def checkIndex
    if Ffmpeg.try_unlock?(self.video_path)
      self.processed = true
      self.save
      return true
    end
    return false
  end
  
  def processing
    return Ffmpeg.locked?(self.video_path)
  end
  
  def setThumbnail(cover)
    if cover && cover.content_type.include?('image/')
      delFile(self.cover_path.to_s + ".png")
      delFile(self.cover_path.to_s + "-small.png")
      File.open(self.cover_path.to_s + '.png', 'wb') do |file|
        file.write(cover.read)
        file.flush()
      end
      Ffmpeg.extractTinyThumbFromExisting(self.cover_path)
    elsif !self.audio_only
      Ffmpeg.extractThumbnail(self.video_path, self.cover_path, self.getDuration().to_f / 2)
    end
  end
  
  def tiny_thumb(user)
    if (self.hidden && (!user || self.user_id != user.id)) || self.isSpoileredBy(user)
      return '/images/default-cover-small.png'
    end
    return '/cover/' + self.id.to_s + '-small.png'
  end
  
  def drop_tags(ids)
    Tag.where('id IN (?) AND video_count > 0', ids).update_all('video_count = video_count - 1')
    VideoGenre.where('video_id = ? AND tag_id IN (?)', self.id, ids).delete_all
  end
  
  def pick_up_tags(ids)
    Tag.where('id IN (?)', ids).update_all('video_count = video_count + 1')
    return self.video_genres
  end
  
  def tag_string
    return Tag.tag_string(self.tags)
  end
  
  def artists_string
    return Tag.tag_string(self.tags.where(tag_type_id: 1))
  end
  
  def getComputedScore
    if self.score.nil?
      computeScore()
    end
    return self.score
  end
  
  def upvote(user, incr)
    incr = incr.to_i
    vote = user.votes.where(:video_id => self.id).first
    if vote.nil?
      vote = user.votes.create(video_id: self.id, negative: false)
    else
      if incr < 0
        vote.destroy
      elsif incr > 0
        if vote.negative
          self.downvotes = self.downvotes - 1
        end
        vote.negative = false
        vote.save
      end
    end
    self.upvotes = computeCount(incr, self.upvotes)
    computeScore()
    return self.upvotes
  end
  
  def downvote(user, incr)
    incr = incr.to_i
    vote = user.votes.where(:video_id => self.id).first
    if vote.nil?
      vote = user.votes.create(video_id: self.id, negative: true)
    else
      if incr < 0
        vote.destroy
      elsif incr > 0
        if !vote.negative
          self.upvotes = self.upvotes - 1
        end
        vote.negative = true
        vote.save
      end
    end
    self.downvotes = computeCount(incr, self.downvotes)
    computeScore()
    return self.downvotes
  end
  
  def star(user)
    return user.stars.toggle(self)
  end
  
  def mix_string(user)
    result = self.tags.select do |t|
      !(user.hides([t.id]) || user.spoilers([t.id])) && t.video_count > 1
    end
    return result.map(&:name).sort().join(' | ')
  end
  
  def json
    return {
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
  
  def isHiddenBy(user)
    if user
      return user.hides(@tag_ids || (@tag_ids = self.tags.map(&:id)))
    end
    return false
  end
  
  def isSpoileredBy(user)
    if user
      return user.spoilers(@tag_ids || (@tag_ids = self.tags.map(&:id)))
    end
    return false
  end
  
  def isUpvotedBy(user)
    if user
      vote = user.votes.where(:video_id => self.id).first
      return !vote.nil? && !vote.negative
    end
    return false
  end
  
  def isDownvotedBy(user)
    if user
      vote = user.votes.where(:video_id => self.id).first
      return !vote.nil? && vote.negative
    end
    return false
  end
  
  def isStarredBy(user)
    if user
      return !user.album_items.where(:video_id => self.id).first.nil?
    end
    return false
  end
  
  def getTitle
    return self.title || "Untitled Video"
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
    return self
  end
  
  def getDuration
    if self.hidden
      return 0
    end
    if self.length.nil? || self.length == 0
      return computeLength()
    end
    return self.length
  end
  
  def period
    if self.created_at > Time.zone.now.beginning_of_day
      return "Today"
    end
    if self.created_at > Time.zone.now.yesterday.beginning_of_day
      return "Yesterday"
    end
    if self.created_at > Time.zone.now.beginning_of_week
      return "Earlier this Week"
    end
    if self.created_at > Time.zone.now.beginning_of_month
      return "Earlier this Month"
    end
    self.created_at.strftime('%B %Y')
  end
  
  def computeHotness
    s = self.views
    s += 2 * (self.score || 0)
    s += 3 * self.comment_thread.comments.count
    basescore = Math.log([s, 1].max)
    
    timediff = (DateTime.now - self.created_at.to_datetime).weeks
    if timediff > 3
      x = timediff - 1
      basescore *= Math.exp(-8 * x * x)
    end
    return basescore
  end
  
  protected
  def delFile(path)
    if File.exists?(path)
      File.delete(path)
    end
  end
  private
  def move_files(from, to)
    renameFile(Video.video_file_path(from, self), Video.video_file_path(to, self))
    renameFile(Video.webm_file_path(from, self), Video.webm_file_path(to, self))
  end
  
  def renameFile(from, to)
    if File.exists?(from)
      File.rename(from, to)
    end
  end
  
  def computeLength
    if self.file
      self.length = Ffmpeg.getVideoLength(self.video_path)
      save()
      return self.length
    end
    return 0
  end
  
  def computeScore
    self.score = self.upvotes - self.downvotes
    self.heat = self.computeHotness
    save()
  end
  
  def computeCount(incr, count)
    if count.nil? || count == nil
      count = 0
    end
    if incr < 0 && count > 0
      return count - 1
    end
    if incr > 0
      return count + 1
    end
    return count
  end
end