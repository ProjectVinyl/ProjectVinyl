class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :video

  scope :up, -> { where(negative: false) }
  scope :down, -> { where(negative: true) }
end
