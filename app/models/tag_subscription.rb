class TagSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :tag

  def self.notify_subscribers(gained, dropped, preserved)
    return if gained.empty? && dropped.empty?
    if !preserved.empty?
      preserved_recievers = TagSubscription.where('tag_id IN (?)', preserved).uniq.pluck(:user_id)
    else
      preserved_recievers = []
    end
    preserved_recievers << 0
    update_users(true, gained, preserved_recievers)
    update_users(false, dropped, preserved_recievers)
  end

  def self.get_feed_items(user)
    video_ids = VideoGenre.joins('INNER JOIN `tag_subscriptions` ON `video_genres`.tag_id = `tag_subscriptions`.tag_id')
                          .where('`tag_subscriptions`.user_id = ? AND `tag_subscriptions`.watch = true AND `tag_subscriptions`.hide = false', user.id)
                          .uniq.pluck(:video_id)
    Video.finder.where('id IN (?)', video_ids).order(:updated_at, :created_at)
  end

  def toggle_hidden
    self.hide = !self.hide
    if self.hide
      self.watch = false
      self.spoiler = false
    end
    self.toggled
    self.hide
  end

  def toggle_spoilered
    self.spoiler = !self.spoiler
    if self.spoiler
      self.hide = false
    end
    self.toggled
    self.spoiler
  end

  def toggle_watched
    self.watch = !self.watch
    if self.watch
      self.hide = false
    end
    self.toggled
    self.watch
  end
  
  private
  def update_users(op, tags, preserved_receivers)
    if !tags.empty?
      User.joins('INNER JOIN `tag_subscriptions` ON user_id = `users`.id')
          .where("`tag_subscriptions`.tag_id IN (?) AND `users`.id NOT IN (?)#{op ? '' : ' AND feed_count > 0'}", gained, preserved_receivers)
          .group('`users`.id').update_all("feed_count = feed_count #{op ? "+" : "-"} 1")
    end
  end
  
  def toggled
    if self.watch == self.spoiler && self.spoiler == self.hide && self.hide == false
      return self.destroy
    end
    self.save
  end
end
