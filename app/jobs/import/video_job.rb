require 'projectvinyl/web/youtube'
require 'projectvinyl/web/the_pony_archive'
require 'projectvinyl/web/ajax'

module Import
  class VideoJob < ApplicationJob
    queue_as :default
    
    def self.create_video(user, yt_id)
      begin
        raise 'Invalid length: Id must be 11 characters' if yt_id.length != 11
        video = user.videos.create(
          title: "Untitled Import #{yt_id}",
          description: '',
          source: "https://www.youtube.com/watch?v=#{yt_id}",
          upvotes: 0,
          downvotes: 0,
          views: 0,
          duplicate_id: 0,
          hidden: true,
          listing: 2,
          processed: false,
          draft: true,
          audio_only: false
        )

        begin
          VideoJob.query_importable_data(yt_id) do |data, archived|
            yield(video, data, archived)
          end
        rescue Exception => e
          video.destroy
          raise e
        end

        Video.transaction do
          video.external_sources.create(key: yt_id, provider: 'youtube').save
          @comments = video.create_comment_thread(user: user, title: video.title)
          @comments.subscribe(user) if user.subscribe_on_upload?
        end

        {
          response: 'The video will be imported shortly',
          id: video.id,
          ok: true
        }
      rescue Exception => e
        raise e
        return {
          response: "Error: Could not schedule action: #{e}",
          ok: false
        }
      end
    end
    
    def self.query_importable_data(yt_id)
      data = ProjectVinyl::Web::Youtube.get("https://www.youtube.com/watch?v=#{yt_id}", {
        title: true, description: true, artist: true, tags: true
      })
      archived = ProjectVinyl::Web::ThePonyArchive.video_meta(yt_id)
      
      yield(data, archived)
    end

    def perform(user_id, yt_id)    
      # Stub for now
    end
  end
end