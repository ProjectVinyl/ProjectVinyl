module Taggable
  extend ActiveSupport::Concern

  def is_hidden_by(user)
    user && user.hides(@tag_ids || (@tag_ids = tags.map(&:id)))
  end

  def is_spoilered_by(user)
    user && user.spoilers(@tag_ids || (@tag_ids = tags.map(&:id)))
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
