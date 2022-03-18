class TagTypeImplication < ApplicationRecord
  belongs_to :tag_type
  belongs_to :implied, class_name: "Tag"

  scope :unique_tag_ids, -> {
    includes(:implied).map(&:implied).map{|tag| tag.alias_id || tag.id}
  }

  def unique_tag_ids
    implied.pluck(:alias_id, :id).map{ |tag| tag[0] || tag[1] }
  end

  def self.compute_new_implications(new_tags, result)
    return [] if !new_tags.length

    imp_groupings = __group_by_implication(new_tags)
    return [] if !imp_groupings.keys.length

    found_imps = joins(:implied)
        .where(tag_type_id: imp_groupings.keys)
        .includes(:implied)
        .pluck(:tag_type_id, :alias_id, :implied_id)
        .map{ |imp| [ imp_groupings[imp[0]].uniq, imp[1] || imp[2]] }

    result += found_imps.pluck(1)
    found_imps.map{ |imp| __ids_to_imps(imp[0], imp[1]) }.flatten
  end

  private
  def self.__group_by_implication(tags)
    mapping = {}
    tags.each{ |tag| __push_id(mapping, tag["tag_type_id"].to_i, tag["id"].to_i) }
    mapping
  end

  def self.__push_id(mapping, type_id, id = nil)
    return if !type_id
    mapping[type_id] = [] if !mapping[type_id]
    mapping[type_id] << id if !id.nil?
  end

  def self.__ids_to_imps(tag_ids, implied_id)
    tag_ids.map{ |tag_id| { tag_id: tag_id, implied_id: implied_id } }
  end
end
