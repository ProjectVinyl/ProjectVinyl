class TagTypeImplication < ApplicationRecord
  belongs_to :tag_type
  belongs_to :implied, class_name: "Tag"
end
