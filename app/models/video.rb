class Video < ActiveRecord::Base
  belongs_to :artist
  has_many :album_items
  has_many :albums, :through => :album_items
end