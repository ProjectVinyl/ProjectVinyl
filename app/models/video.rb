class Video < ActiveRecord::Base
  belongs_to :artist
  has_many :album_items
  has_many :albums, :through => :album_items
  has_many :video_genres
  has_many :genres, :through => :video_genres
  
  def transferTo(artist)
    self.artist = artist
    self.save
  end
  
  def removeSelf
    delFile(self.video_path)
    delFile(self.cover_path.to_s + ".png")
    delFile(self.cover_path.to_s + "-small.png")
    delFile(Rails.root.join('public', 'stream', self.id.to_s + '.webm'))
    self.album_items.destroy
    self.destroy
  end
  
  def video_path
    return Rails.root.join('public', 'stream', self.id.to_s + self.file)
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
  
  def preload_genres
    self.video_genres.delete_all
    return self.video_genres
  end
  
  def genres_string
    return Genre.tag_string(self.genres)
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
  
  def getDuration
    if self.hidden
      return 0
    end
    if self.length.nil? || self.length == 0
      return computeLength()
    end
    return self.length
  end
  
  private
  def delFile(path)
    if File.exists?(path)
      File.delete(path)
    end
  end
  
  def computeLength
    file = Rails.root.join('public', 'stream', self.id.to_s + (self.audio_only ? '.mp3' : '.webm')).to_s
    if !self.audio_only && !File.exists?(file)
      file = Rails.root.join('public', 'stream', self.id.to_s + '.mp4').to_s
    end
    self.length = Ffmpeg.getVideoLength(file)
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