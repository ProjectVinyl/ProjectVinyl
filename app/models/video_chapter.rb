class VideoChapter < ApplicationRecord
  belongs_to :video
  
  scope :to_json, ->{
    pluck(:title, :timestamp).map{|entry| {title: entry[0], time: entry[1]} }
  }
end
