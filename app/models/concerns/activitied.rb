module Activitied
  extend ActiveSupport::Concern
  
  included do
    scope :online, -> { where('last_active_at > ?', Time.zone.now - 3.minutes) }
  end
  
  def poke
    return if online?
    touch(:last_active_at)
    return if new_record?
    save
  end
  
  def online?
    last_active_at != nil && last_active_at > Time.zone.now - 3.minutes
  end
end
