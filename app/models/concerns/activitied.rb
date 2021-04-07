module Activitied
  extend ActiveSupport::Concern

  included do
    scope :online, -> { where('last_active_at > ?', Time.zone.now - 3.minutes) }
    scope :active_since, ->since {
      where('last_active_at > ? OR updated_at > ?', since, since)
      .order('last_active_at IS NOT NULL', :last_active_at, :updated_at)
    }
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

  def away?
    last_active_at != nil && last_active_at > Time.zone.now - 15.minutes
  end

  def online_status
    return :online if online?
    return :away if away?
    :offline
  end
end
