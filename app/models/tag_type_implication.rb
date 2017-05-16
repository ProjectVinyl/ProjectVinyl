class TagTypeImplication < ActiveRecord::Base
  belongs_to :tag_type
  belongs_to :implied, class_name: "Tag"
end
