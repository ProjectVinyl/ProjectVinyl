class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true
  
  scope :today, -> { where('started_at > ?', Time.zone.now.beginning_of_day) }
  scope :yesterday, -> { where('started_at > ? AND started_at < ?', Time.zone.now.beginning_of_day - 1.day, Time.zone.now.beginning_of_day) }
end
