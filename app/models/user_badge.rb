class UserBadge < ActiveRecord::Base
  belongs_to :user
  belongs_to :badge
  
  def title(user)
    type = badge.type
    if type == 1
      return custom_title
    end
    return badge.title
  end
  
  def icon
    self.badge.icon
  end
  
  def colour
    self.badge.colour
  end
end