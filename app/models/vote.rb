class Vote < ApplicationRecord
  include Statable
  
  belongs_to :user
  belongs_to :video
  
  scope :up, -> { where(negative: false) }
  scope :down, -> { where(negative: true) }

  def self.set_count(sender, negative, value)
    if negative
      sender.downvotes = [0, sender.downvotes.to_i + value].max
    else
      sender.upvotes = [0, sender.upvotes.to_i + value].max
    end
  end
  
  def self.vote(user, sender, incr, negative)
    vote = user.votes.where(video_id: sender.id).first
    
    if vote.nil?
      vote = user.votes.create(video_id: sender.id, negative: negative)
      
      Vote.set_count(sender, negative, 1)
    elsif incr.to_i < 0
      vote.destroy
      Vote.set_count(sender, negative, -1)
    elsif vote.negative != negative
      vote.negative = negative
      vote.save
      
      Vote.set_count(sender, negative, 1)
      Vote.set_count(sender, !negative, -1)
    end
  end
end
