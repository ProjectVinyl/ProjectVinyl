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
    self.wilson_lower_bound, self.wilson_upper_bound = ci_bounds(upvotes, upvotes + downvotes)
    compute_hotness(defer)
  end

  private
  def __play_boots
    (play_count || 0).to_f
  end

  def __view_boosts
    [(views || 0), 1].max.to_f
  end

  def __comment_boosts
    comment_thread.comments.map{|comment| 1 + comment.likes_count }.sum
  end

  def __boost_multiplier
    x = (__play_boots / __view_boosts) + (2 * __comment_boosts) + (3 * wilson_lower_bound)
    x * 1000
  end
end
