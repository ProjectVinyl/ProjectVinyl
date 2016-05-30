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
  
  def upvote(user, incr)
    incr = incr.to_i
    vote = user.votes.where(:video_id => self.id).first
    if vote.nil?
      vote = user.votes.new(video_id: self.id, negative: false)
      vote.save
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
      vote = user.votes.new(video_id: self.id, negative: true)
      vote.save
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
    vote = user.stars.where(:video_id => self.id).first
    if !vote
      vote = user.stars.new(video_id: self.id)
      vote.save
      return true
    else
      vote.destroy
      return false
    end
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
      return !user.stars.where(:video_id => self.id).first.nil?
    end
    return false
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