module Queues
  extend ActiveSupport::Concern
  
  def queue(excluded, sender)
    user_queue = self.get_queue(excluded)
    {
      user: user_queue[:videos].with_likes(sender),
      global: Video.listable
        .where.not('videos.id = ? OR videos.id IN (?)', excluded, user_queue[:ids])
        .random(7)[:videos].with_likes(sender)
    }
  end
  
  protected
  def get_queue(excluded)
    self.videos.listable.where.not(id: excluded).random(7)
  end
end
