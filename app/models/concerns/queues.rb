module Queues
  extend ActiveSupport::Concern
  
  def queue(excluded, sender)
    user_queue = self.get_queue(excluded)
    {
      user: user_queue[:videos].with_likes(sender),
      global: Video.listable
        .where.not('id = ? OR id IN (?)', excluded, user_queue[:ids])
        .random_videos(7)[:videos].with_likes(sender)
    }
  end
  
  private
  def get_queue(excluded)
    self.videos.listable.where.not(id: excluded).random_videos(7)
  end
end
