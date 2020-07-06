module Periodic
  extend ActiveSupport::Concern

  def self.begins
    [
      ["Today", Time.zone.now.beginning_of_day, 0],
      ["Yesterday", Time.zone.now.yesterday.beginning_of_day, 1],
      ["Earlier this Week", Time.zone.now.beginning_of_week, 2],
      ["Last Week", Time.zone.now.beginning_of_week - 1.week, 3],
      ["Two Weeks Ago", Time.zone.now.beginning_of_week - 2.weeks, 4],
      ["Earlier this Month", Time.zone.now.beginning_of_month, 5],
      ["Earlier this Month", Time.zone.now.beginning_of_month, 5]
    ]
  end

  included do
    scope :by_period, -> {
      group_by(&:period).each { yield }
      self
    }
  end

  def period_search_range
    return "uploaded>#{period_begin.to_date},uploaded<#{period_end.to_date}"
  end

  def period_begin
    period_pair{ ["", self.created_at.beginning_of_month, -1] }[1]
  end

  def period_end
    pair = period_pair { ["", self.created_at.end_of_month + 1.day, -1] }
    return Periodic.begins[pair[2] - 1][1] if pair[2] > 0
    return Time.zone.now if pair[2] == 0
    pair[1]
  end

  def period_pair
    matches = Periodic.begins.filter{|a| self.created_at > a[1]}
    return matches[0] if matches.length > 0
    yield
  end

  def period
    period_pair{ [self.created_at.strftime('%B %Y'), self.created_at, -1] }[0]
  end
end
