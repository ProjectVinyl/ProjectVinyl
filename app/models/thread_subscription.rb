class ThreadSubscription < ActiveRecord::Base
  belongs_to :thread
  has_one :user
end
