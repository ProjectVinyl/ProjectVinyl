class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :video
  
  scope :up, -> { where(negative: false) }
  scope :down, -> { where(negative: true) }
  
  def self.vote(user, sender, incr, negative)
    votes = (negative ? sender.downvotes : sender.upvotes).to_i
    opposing_votes = (negative ? sender.upvotes : sender.downvotes).to_i
    
    vote = user.votes.where(video_id: sender.id).first
    if vote.nil?
      vote = user.votes.create(video_id: sender.id, negative: negative)
      votes += 1
    else
      if incr.to_i < 0
        vote.destroy
        votes -= 1 if votes > 0
      else
        if vote.negative != negative
          opposing_votes -= 1 if opposing_votes > 0
          votes += 1
          vote.negative = negative
          vote.save
        end
      end
    end
    
    sender.downvotes = negative ? votes : opposing_votes
    sender.upvotes = negative ? opposing_votes : votes
  end
  
end
