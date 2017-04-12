module Queues
  extend ActiveSupport::Concern
  
  def queue(excluded)
    return Video.randomVideos(self.videos.listable.where.not(id: excluded), 7)[:videos]
  end
  
  def queuev2(excluded)
    user_queue = Video.randomVideos(self.videos.listable.where.not(id: excluded), 7)
    return {
      user: user_queue[:videos],
      global: Video.randomVideos(Video.listable.where.not('id != ? && id IN (?)', excluded, user_queue[:ids]), 7)[:videos]
    }
  end
end