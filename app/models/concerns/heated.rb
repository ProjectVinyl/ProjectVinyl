module Heated
  extend ActiveSupport::Concern

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

  def compute_hotness
    x = views || 0
    x += 2 * (upvotes || 0)
    x += 2 * (downvotes || 0)
    x += 3 * comment_thread.comments.count
    basescore = Math.log([x, 1].max)

    n = DateTime.now
    c = created_at.to_datetime
    if c < (n - 3.weeks)
      x = ((n - c).to_f / 7) - 1
      basescore *= Math.exp(-8 * x * x)
    end

    self.heat = basescore * 1000
    self
  end

  protected

  def compute_score
    self.score = upvotes - downvotes
    self.update_index(defer: false)
    self.compute_hotness.save
  end
end
