require 'projectvinyl/web/youtube'

class ProcessExternalSourcesJob < ApplicationJob
  queue_as :high_priority

  def perform()
    Video.in_batches do |videos|
      videos = videos.pluck(:id, :source).filter{|v| ProjectVinyl::Web::Youtube.is_video_link(v[1])}
      videos = videos.map do |v|
        {
          provider: 'youtube',
          video_id: v[0],
          key: ProjectVinyl::Web::Youtube.video_id(v[1])
        }
      end
      ExternalSource.create(videos)
    end
  end
end
