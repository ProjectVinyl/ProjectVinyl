class TagType < ApplicationRecord
  include Taggable

  has_many :tag_type_implications, dependent: :destroy
  has_many :tags, through: :tag_type_implications, source: :implied
  has_many :referrers, class_name: "Tag"

  after_destroy :unlink_tags

  def self.for_tag_name(name)
    return nil if name.index(':').nil?
    TagType.where(prefix: name.split(':')[0]).first
  end

  def find_and_assign
    Tag.transaction do
      Tag.where('name LIKE ?', self.prefix + ':%').update_all(tag_type_id: self.id)
      Tag.where(tag_type_id: self.id).find_each(&:validate_name_and_reindex)
    end
  end

  def drop_tags(ids)
    tag_type_implications.where('implied_id IN (?)', ids).delete_all
  end

  def pick_up_tags(ids)
    TagTypeImplication.create(ids_to_type_imps ids)
    nil
  end

  def self.upsert_implications(existing_tags, new_tags, result)
    new_tag_type_map = {}
    new_tags.each do |tag|
      type_id = tag["tag_type_id"].to_i
      id = tag["id"].to_i
      if type_id
        new_tag_type_map[type_id] = [] if !new_tag_type_map[type_id]
        new_tag_type_map[type_id] << id
      end

      result << id
    end
    existing_tags.each do |tag|
      new_tag_type_map[tag.tag_type_id] = [] if !new_tag_type_map[tag.tag_type_id]
    end

    new_mps = []
    new_tag_type_map.each do |id, tag_ids|
      imps = TagTypeImplication.where(tag_type_id: id).unique_tag_ids
      if imps.length
        result += imps
        new_mps += TagType.ids_to_imps(tag_ids, imps)
      end
    end

    TagImplication.upsert_all(new_mps, returning: false, unique_by: [:tag_id, :implied_id])
  end

  private
  def self.ids_to_type_imps(imps)
    imps.map{|implied_id| { implied_id: implied_id, tag_type_id: id } }
  end

  def self.ids_to_imps(tag_ids, imps)
    imps.map{|implied_id| tag_ids.map{ |tag_id| { tag_id: tag_id, implied_id: implied_id } } }.flatten
  end

  def unlink_tags
    Tag.where(tag_type_id: id).update_all('tag_type_id = 0')
  end
end
