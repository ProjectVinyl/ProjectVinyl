module Taggable
  extend ActiveSupport::Concern
  
  def drop_tags(ids)
  end
  
  def pick_up_tags(ids)
  end
  
  def tags_changed
    self.update_index(defer: false)
  end
  
  def tag_string
    Tag.tag_string(self.tags)
  end
end
