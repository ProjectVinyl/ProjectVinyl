class BadgeInstance
  def initialize(title, icon, colour, &block)
    @title = title
    @icon = icon
    @colour = colour
    @block = block
    @adv_title = false
  end
  
  def get_title(user)
    if @adv_title
      return @adv_title.call(user)
    end
    title
  end
  
  def title
    @title
  end
  
  def icon
    @icon
  end
  
  def colour
    @colour
  end
  
  def adv_title(&block)
    @adv_title = block
    self
  end
  
  def matches(user)
    (user && !user.isDummy && @block.call(user))
  end
end

class Badge < ActiveRecord::Base
  Types = [
    BadgeInstance.new('Admin', 'star', 'orange'){|user| user.admin?},
    BadgeInstance.new('Moderator', 'gavel', 'orange'){|user| user.contributor?},
    (BadgeInstance.new('Artist', 'paint-brush', 'green'){|user| !user.tag_id.nil?}).adv_title{|user| 'Artist - ' + user.tag.name.split(':')[1]}
  ]
  
  def self.static_badges
    return Types
  end
  
  def hidden
    false
  end
  
  def get_title(user)
    title
  end
  
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