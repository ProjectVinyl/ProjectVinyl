class Video < ActiveRecord::Base
  belongs_to :artist
  has_many :album_items
  has_many :albums, :through => :album_items
  has_many :video_genres
  has_many :genres, :through => :video_genres
  
  def getComputedScore
    if self.score.nil?
      computeScore()
    end
    return self.score
  end
  
  def upvote(incr)
    self.upvotes = computeCount(incr.to_i, self.upvotes)
    computeScore()
    return self.upvotes
  end
  
  def downvote(incr)
    self.upvotes = computeCount(incr.to_i, self.downvotes)
    computeScore()
    return self.downvotes
  end
  
  def getDuration
    if self.length.nil? || self.length == 0
      return computeLength()
    end
    return self.length
  end
  
  private
  def computeLength
    file = Rails.root.join('public', 'stream', self.id.to_s + (self.audio_only ? '.mp3' : '.webm')).to_s
    self.length = ::Ffmpeg.getVideoLength(file)
puts self.length
    save()
    return self.length
  end
  
  def computeScore
    self.score = self.upvotes - self.downvotes
    save()
  end
  
  def computeCount(incr, count)
    if count.nil?
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