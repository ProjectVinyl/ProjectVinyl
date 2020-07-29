require 'projectvinyl/elasticsearch/activerecord/selector'

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

  def self.get_feed_items(user, current_filter)
    tag_ids = Tag.expand_implications(user.tag_subscriptions.where(watch: true, hide: false).pluck(:tag_id))
    tags = Tag.actualise(Tag.where('id IN (?)', tag_ids).includes(:alias)).map(&:name).uniq

    return current_filter.videos
        .filter({ terms: { tags: tags } })
        .filter({ terms: { listing: [0, 1] } })
        .where(hidden: false, duplicate_id: 0)
        .order(:updated_at, :created_at)
        .records
        .with_tags.with_likes(user)
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
  
  protected
  def self.update_users(op, tags, preserved_receivers)
    if !tags.empty?
      User.joins('INNER JOIN tag_subscriptions ON user_id = users.id')
          .where("tag_subscriptions.tag_id IN (?) AND users.id NOT IN (?)#{op ? '' : ' AND feed_count > 0'}", tags, preserved_receivers)
          .group('users.id').update_all("feed_count = feed_count #{op ? "+" : "-"} 1")
    end
  end
  
  def toggled
    if self.watch == self.spoiler && self.spoiler == self.hide && self.hide == false
      return self.destroy
    end
    self.save
  end
end
