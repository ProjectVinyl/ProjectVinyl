class MoreBadges < ActiveRecord::Migration
  def change
    Badge.where(id: 3).update_all(icon: 'silverbit')
    Badge.where(id: 4).update_all(icon: 'goldbit')
    Badge.create(title: 'Tom', colour: 'grey', icon: 'tom', badge_type: 0)
    Badge.create(title: 'Gem', colour: 'white', icon: 'gem', badge_type: 0)
  end
end
