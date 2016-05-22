class Album < ActiveRecord::Base
  belongs_to :artist
  has_many :album_items
  has_many :videos, :through => :album_items
end