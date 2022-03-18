class TagImplication < ApplicationRecord
  include Upsert

  belongs_to :implicator, class_name: 'Tag', foreign_key: 'tag_id'
  belongs_to :implication, class_name: 'Tag', foreign_key: 'implied_id'

  scope :expand, ->(tag_ids) { tag_ids | where('tag_id IN (?)', tag_ids).pluck(:implied_id) }

  def self.load(tag, ids)
    where(tag_id: tag.id).destroy_all
    create(ids.uniq.map{|i| { tag_id: tag.id, implied_id: i } })
  end

  def self.upsert_implications(new_tags, result)
    new_imps = TagTypeImplication.compute_new_implications(new_tags, result)

    return if !new_imps.length
    upsert_all(new_imps, returning: false, unique_by: [:tag_id, :implied_id])
  end
end
