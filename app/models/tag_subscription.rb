class TagSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag
  
  def self.notify_subscribers(gained, dropped, preserved)
    if gained.length == 0 && dropped.length == 0
      return
    end
    if preserved.length > 0
      preserved_recievers = TagSubscription.where('tag_id IN (?)', preserved).uniq.pluck(:user_id)
    else
      preserved_recievers = []
    end
    preserved_recievers << 0
    if gained.length > 0
      User.joins('INNER JOIN `tag_subscriptions` ON user_id = `users`.id').where('`tag_subscriptions`.tag_id IN (?) AND `users`.id NOT IN (?)', gained, preserved_recievers).group('`users`.id').update_all('feed_count = feed_count + 1')
    end
    if dropped.length > 0
      User.joins('INNER JOIN `tag_subscriptions` ON user_id = `users`.id').where('`tag_subscriptions`.tag_id IN (?) AND `users`.id NOT IN (?) AND feed_count > 0', dropped, preserved_recievers).group('`users`.id').update_all('feed_count = feed_count - 1')
    end
  end
  
  def self.get_feed_items(user)
    video_ids = VideoGenre.joins('INNER JOIN `tag_subscriptions` ON `video_genres`.tag_id = `tag_subscriptions`.tag_id').where('`tag_subscriptions`.user_id = ? AND `tag_subscriptions`.watch = true AND `tag_subscriptions`.hide = false', user.id).uniq.pluck(:video_id)
    return Video.Finder.where('id IN (?)', video_ids).order(:updated_at, :created_at)
  end
  
  def toggle_hidden
    self.hide = !self.hide
    if self.hide && self.watch
      self.watch = false
    end
    if self.hide && self.spoiler
      self.spoiler = false
    end
    if self.watch == self.spoiler && self.spoiler == self.hide && self.hide == false
      self.destroy
    else
      self.save
    end
    return self.hide
  end
  
  def toggle_spoilered
    self.spoiler = !self.spoiler
    if self.spoiler && self.hide
      self.hide = false
    end
    if self.watch == self.spoiler && self.spoiler == self.hide && self.hide == false
      self.destroy
    else
      self.save
    end
    return self.spoiler
  end
  
  def toggle_watched
    self.watch = !self.watch
    if self.watch && self.hide
      self.hide = false
    end
    if self.watch == self.spoiler && self.spoiler == self.hide && self.hide == false
      self.destroy
    else
      self.save
    end
    return self.watch
  end
end
