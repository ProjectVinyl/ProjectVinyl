class TagSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :tag

  scope :expanded_tags, -> { TagImplication.expand(pluck(:tag_id)) }

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
    tag_ids = user.tag_subscriptions.where(watch: true, hide: false).expanded_tags
    tags = Tag.where('id IN (?)', tag_ids).actual_names

    return current_filter.videos
        .filter({ terms: { tags: tags } })
        .filter({ terms: { listing: [0, 1] } })
        .where(hidden: false, duplicate_id: 0)
        .order(:updated_at, :created_at)
        .records
        .for_thumbnails(user)
  end

  protected
  def self.update_users(op, tags, preserved_receivers)
    if !tags.empty?
      User.joins('INNER JOIN tag_subscriptions ON user_id = users.id')
          .where("tag_subscriptions.tag_id IN (?) AND users.id NOT IN (?)#{op ? '' : ' AND feed_count > 0'}", tags, preserved_receivers)
          .group('users.id')
          .update_all("feed_count = feed_count #{op ? "+" : "-"} 1")
    end
  end
end
