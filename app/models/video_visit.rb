class VideoVisit < ApplicationRecord
  belongs_to :video
  belongs_to :ahoy_visit, class_name: "Ahoy::Visit"
end
