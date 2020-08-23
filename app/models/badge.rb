class BadgeInstance
  def initialize(title, icon, colour, &block)
    @title = title
    @icon = icon
    @colour = colour
    @block = block
    @adv_title = false
  end

  def title_for(user)
    @adv_title ? @adv_title.call(user) : title
  end

  attr_reader :title
  attr_reader :icon
  attr_reader :colour

  def adv_title(&block)
    @adv_title = block
    self
  end

  def matches?(user)
    user && !user.dummy? && @block.call(user)
  end

  def description
    'Automatically Assigned'
  end
end

class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy

  Types = [
    BadgeInstance.new('Admin', 'star', 'orange', &:admin?),
    BadgeInstance.new('Moderator', 'gavel', 'orange', &:contributor?),
    (BadgeInstance.new('Artist', 'paint-brush', 'green') { |user| !user.tag_id.nil? }).adv_title { |user| 'Artist - ' + user.tag.name.split(':')[1] }
  ].freeze

  def self.static_badges
    Types
  end

  def hidden
    false
  end

  def title_for(_user)
    title
  end

  def self.all_badges(user)
    return if user.nil? || user.dummy?
    Types.each do |o|
      yield(o) if o.matches?(user)
    end
    user.user_badges.each do |o|
      yield(o)
    end
  end
end
