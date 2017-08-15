class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :video

  scope :up, -> { where(negative: false) }
  scope :down, -> { where(negative: true) }
  
  def self.compute_count(incr, count)
    count = 0 if count.nil? || count.nil?
    return count - 1 if incr < 0 && count > 0
    return count + 1 if incr > 0
    count
  end
  
  def self.vote(user, sender, incr, votes, negative)
    incr = incr.to_i
    vote = user.votes.where(video_id: sender.id).first
    if vote.nil?
      vote = user.votes.create(video_id: sender.id, negative: negative)
    else
      if incr < 0
        vote.destroy
      elsif incr > 0
        if vote.negative != negative
          votes -= 1
          vote.negative = negative
          vote.save
        end
      end
    end
    Vote.compute_count(incr, votes)
  end
end
