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
    tag_type_implications.where('implied_id IN (?)', ids).delete_all
  end

  def pick_up_tags(ids)
    TagTypeImplication.create(__ids_to_type_imps ids)
    nil
  end

  def create_implications!(tag)
    TagImplication.create(__ids_to_imps(tag.id, imps)) if (imps = unique_implication_ids).length
    imps
  end

  def unique_implication_ids
    tag_type_implications.unique_tag_ids
  end

  private
  def __ids_to_type_imps(imps)
    imps.map{|implied_id| { implied_id: implied_id, tag_type_id: id } }
  end

  def __ids_to_imps(tag_id, imps)
    imps.map{|implied_id| { tag_id: tag_id, implied_id: implied_id } }
  end
end
