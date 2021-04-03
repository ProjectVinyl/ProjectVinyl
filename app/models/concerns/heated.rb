module Heated
  extend ActiveSupport::Concern
  include Wilson

  def upvote(user, incr)
    Vote.vote(user, self, incr, false)
    compute_score
    upvotes
  end

  def downvote(user, incr)
    Vote.vote(user, self, incr, true)
    compute_score
    downvotes
  end

  def get_computed_score
    compute_score if score.nil?
    score
  end

  def compute_hotness(defer = true)
    touch(:boosted_at)
    self.heat = __boost_multiplier
    save
    update_index(defer: defer)
    self
  end

  def compute_score(defer = true)
    self.score = upvotes - downvotes
    self.wilson_lower_bound, self.wilson_upper_bound = ci_bounds(upvotes, total_votes)
    compute_hotness(defer)
  end
  
  def total_votes
    upvotes + downvotes
  end
  
  def rating_percentage
    return 0 if total_votes == 0
    upvotes.to_f / total_votes.to_f
  end

  private
  def __play_boost
    (play_count || 0).to_f
  end

  def __view_boost
    [(views || 0), 1].max.to_f
  end

  def __comment_boost
    comment_thread.comments.map{|comment| 1 + (comment.likes_count || 0) }.sum
  end

  def __boost_multiplier
    x = (__play_boost / __view_boost) + (2 * __comment_boost) + (3 * (wilson_lower_bound || 0))
    x * 1000
  end
end
