class UserBadge < ApplicationRecord
  belongs_to :badge
  belongs_to :user

  def title_for(user)
    title(user)
  end

  def title(_user=nil)
    type = badge.badge_type
    if type == 1 && self.custom_title
      return self.badge.title + " - " + self.custom_title
    end
    self.badge.title
  end

  def icon
    self.badge.icon
  end

  def colour
    self.badge.colour
  end
end
