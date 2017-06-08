module Queues
  extend ActiveSupport::Concern

  def queue(excluded)
    Video.random_videos(self.videos.listable.where.not(id: excluded), 7)[:videos]
  end

  def queuev2(excluded)
    user_queue = Video.random_videos(self.videos.listable.where.not(id: excluded), 7)
    {
      user: user_queue[:videos],
      global: Video.random_videos(Video.listable.where.not('id != ? && id IN (?)', excluded, user_queue[:ids]), 7)[:videos]
    }
  end
end
