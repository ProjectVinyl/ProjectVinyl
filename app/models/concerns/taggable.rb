module Taggable
  extend ActiveSupport::Concern

  included do
    scope :with_tags, -> { includes(:tags) }
  end

  def hidden_by?(user)
    user && user.hides(@tag_ids || (@tag_ids = tags.map(&:id)))
  end

  def spoilered_by?(user)
    user && user.spoilers(@tag_ids || (@tag_ids = tags.map(&:id)))
  end

  def filtered_by?(user)
    hidden_by?(user) || spoilered_by?(user)
  end

  def drop_tags(ids)
  end

  def pick_up_tags(ids)
  end

  def tags_changed
    self.update_index(defer: false)
  end

  def tag_string
    Tag.tag_string(tags)
  end
end
