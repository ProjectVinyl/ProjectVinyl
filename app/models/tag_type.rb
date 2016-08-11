class TagType < ActiveRecord::Base
  has_many :tag_type_implications, dependent: :destroy
  has_many :implications, :through => :tag_type_implications, foreign_key: "implied_id"
end
