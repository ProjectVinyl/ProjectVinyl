class TagType < ApplicationRecord
  include Taggable
  
  has_many :tag_type_implications, dependent: :destroy
  has_many :tags, through: :tag_type_implications, source: :implied
  has_many :referrers, class_name: "Tag"

  def set_metadata(s, h)
    s = Tag.sanitize_name(s)
    if !StringsHelper.valid_string?(s)
      return "Error: Prefix cannot be blank/null"
    end
    self.hidden = h if self.hidden != h
    if self.prefix != s
      if TagType.where(prefix: s).count > 0
        return "Duplicate error: A tag type with that prefix already exists."
      end
      self.prefix = s
    end
    self.save
    self.find_and_assign
    false
  end

  def find_and_assign
    Tag.transaction do
      Tag.where('name LIKE ?', self.prefix + ':%').update_all(tag_type_id: self.id)
      Tag.where(tag_type_id: self.id).find_each do |tag|
        tag.set_name(tag.name)
      end
    end
  end

  def drop_tags(ids)
    TagTypeImplication.where('tag_type_id = ? AND implied_id IN (?)', self.id, ids).delete_all
  end

  def pick_up_tags(ids)
    Tag.where('id IN (?)', ids).update_all('video_count = video_count + 1')
    ids = ids.map do |o|
      { implied_id: o, tag_type_id: self.id }
    end
    TagTypeImplication.create(ids)
    nil
  end
end
