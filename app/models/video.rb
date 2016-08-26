class Video < ActiveRecord::Base
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  
  has_one :comment_thread, as: :owner, dependent: :destroy
  
  has_many :album_items, dependent: :destroy
  has_many :albums, :through => :album_items
  has_many :video_genres, dependent: :destroy
  has_many :tags, :through => :video_genres
  
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
  
  def self.verify_integrity
    result = [0,0,0,0]
    Video.all.find_in_batches do |o|
      batch = [[],[],[],[]]
      o.each do |v|
        no_src = false
        if !File.exists?(v.video_path)
          result[0] += 1
          batch[0] << v.id
          no_src = true
        end
        if !v.audio_only
          if !File.exists?(v.webm_path)
            result[1] += 1
            batch[1] << v.id
          else
            len = v.length
            if (len.nil? || len == 0) && !no_src
              len = Ffmpeg.getVideoLength(v.video_path)
            end
            if !(len.nil? || len == 0) && len != Ffmpeg.getVideoLength(v.webm_path)
              File.delete(v.webm_path)
              result[3] += 1
              batch[3] << v.id
            end
          end
        end
        if !File.exists?(v.cover_path.to_s + '.png') || !File.exists?(v.cover_path.to_s + "-small.png")
          result[2] += 1
          batch[2] << v.id
          if !no_src
            Ffmpeg.extractThumbnail(v.video_path, v.cover_path, v.getDuration().to_f / 2)
          end
        end
      end
      Video.where('id IN (?)', batch[0]).update_all(hidden: true)
      Video.where('id IN (?)', batch[1] | batch[3]).update_all(processed: nil)
    end
    return result
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
    self.destroy
  end
  
  def video_path
    return Video.video_file_path(self.hidden ? 'private' : 'public', self)
  end
  
  def webm_path
    return Video.webm_file_path(self.hidden ? 'private' : 'public', self)
  end
  
  def self.video_file_path(root, video)
    return Rails.root.join(root, 'stream', video.id.to_s + video.file)
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
    File.open(self.video_path, 'wb') do |file|
      file.write(media.read)
      file.flush()
    end
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
    return self.hidden ? "Hidden Video" : self.title
  end
  
  def set_title(title)
    title = ApplicationHelper.check_and_trunk(title, self.title || "Untitled")
    title = ApplicationHelper.demotify(title)
    self.title = title
    self.safe_title = ApplicationHelper.url_safe(title)
    if self.comment_thread_id
      self.comment_thread.title = title
      self.comment_thread.save
    end
  end
  
  def set_description(text)
    test = ApplicationHelper.demotify(text)
    self.description = text
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
    self.length = Ffmpeg.getVideoLength(self.video_path)
    save()
    return self.length
  end
  
  def computeScore
    self.score = self.upvotes - self.downvotes
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