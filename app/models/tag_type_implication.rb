class TagTypeImplication < ApplicationRecord
  belongs_to :tag_type
  belongs_to :implied, class_name: "Tag"

  scope :unique_tag_ids, -> {
    includes(:implied).map(&:implied).map{|tag| tag.alias_id || tag.id}
  }
end
