module Periodic
  extend ActiveSupport::Concern
  
  included do
    scope :by_period, -> {
      group_by(&:period).each { yield }
      self
    }
  end
  
  def period
    return "Today" if self.created_at > Time.zone.now.beginning_of_day
    if self.created_at > Time.zone.now.yesterday.beginning_of_day
      return "Yesterday"
    end

    if self.created_at > Time.zone.now.beginning_of_week
      return "Earlier this Week"
    end

    if self.created_at > (Time.zone.now.beginning_of_week - 1.week)
      return "Last Week"
    end

    if self.created_at > (Time.zone.now.beginning_of_week - 2.weeks)
      return "Two Weeks Ago"
    end

    if self.created_at > Time.zone.now.beginning_of_month
      return "Earlier this Month"
    end

    self.created_at.strftime('%B %Y')
  end
end
