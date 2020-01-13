class WatchHistory < ApplicationRecord
  belongs_to :user
  belongs_to :video
  
  scope :most_recent, -> { order(:created_at).limit(1) }
end
