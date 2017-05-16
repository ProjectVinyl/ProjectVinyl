class TagType < ActiveRecord::Base
  has_many :tag_type_implications, dependent: :destroy
  has_many :implications, :through => :tag_type_implications, source: :implied
  
  has_many :tags
end
