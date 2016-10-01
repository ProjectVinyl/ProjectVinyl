class BadgeInstance
  def initialize(title, icon, colour, &block)
    @title = title
    @icon = icon
    @colour = colour
    @block = block
  end
  
  def title(user)
    if @adv_title
      return @title.call(user)
    end
    @title
  end
  
  def icon
    @icon
  end
  
  def colour
    @colour
  end
  
  def adv_title(&block)
    @adv_title = true
    @title = block
    self
  end
  
  def matches(user)
    (user && !user.isDummy && @block.call(user))
  end
end

class UserBadge < ActiveRecord::Base
  belongs_to :badge
  belongs_to :user
  
  def title(user)
    type = badge.badge_type
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

class Badge < ActiveRecord::Base
  Types = [
    BadgeInstance.new('Admin', 'gavel', 'orange'){|user| user.is_contributor?},
    (BadgeInstance.new('Artist', 'paint-brush', 'green'){|user| !user.tag_id.nil?}).adv_title{|user| 'Artist - ' + user.tag.name.split(':')[1]}
  ]
  
  def self.all_badges(user)
    if !user || user.isDummy
      return
    end
    Types.each do |o|
      if o.matches(user)
        yield(o)
      end
    end
    user.user_badges.each do |o|
      yield(o)
    end
  end
end