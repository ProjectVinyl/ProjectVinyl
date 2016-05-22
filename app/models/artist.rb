class Artist < ActiveRecord::Base
  has_many :videos
  has_many :albums
end