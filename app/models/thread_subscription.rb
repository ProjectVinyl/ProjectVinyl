class ThreadSubscription < ApplicationRecord
  belongs_to :thread
  has_one :user
end
