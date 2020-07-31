class TagImplication < ApplicationRecord
  belongs_to :implicator, class_name: 'Tag', foreign_key: 'tag_id'
  belongs_to :implication, class_name: 'Tag', foreign_key: 'implied_id'

  scope :expand, ->(tag_ids) { tag_ids | where('tag_id IN (?)', tag_ids).pluck(:implied_id) }

  def self.load(tag, ids)
    where(tag_id: tag.id).destroy_all
    create(ids.uniq.map{|i| { tag_id: tag.id, implied_id: i } })
  end
end
