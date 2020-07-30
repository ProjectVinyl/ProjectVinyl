module Queues
  extend ActiveSupport::Concern

  def queue(excluded, current_user, current_filter)
    user = load_queue_items(current_filter.videos.where(user_id: id), excluded, current_user)
    global = load_queue_items(current_filter.videos.where_not(id: user.pluck(:id).uniq), excluded, current_user)

    { user: user, global: global }
  end

  private
  def load_queue_items(videos, excluded, current_user)
    videos
      .where(hidden: false, duplicate_id: 0)
      .where_not(id: excluded)
      .limit(7)
      .random
      .with_tags
      .with_likes(current_user)
  end
end
