class ArtistGenre < ApplicationRecord
  belongs_to :user
  belongs_to :tag, counter_cache: :user_count
end
