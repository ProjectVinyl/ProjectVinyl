class TagTypeImplication < ApplicationRecord
  belongs_to :tag_type
  belongs_to :implied, class_name: "Tag"

  scope :unique_tag_ids, -> { pluck(:implied_id).uniq }
end
