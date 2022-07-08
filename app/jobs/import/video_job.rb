require 'projectvinyl/web/youtube'
require 'projectvinyl/web/the_pony_archive'
require 'projectvinyl/web/ajax'

module Import
  class VideoJob < ApplicationJob
    queue_as :manual

    def self.queue_and_publish_now(user, yt_id, queue = :default, publish: true)
      Import::VideoJob.create_video(user, yt_id) do |video, data, archived|
        Import::VideoAttributesJob.perform_now(video.id, data, archived, yt_id)
        Import::VideoThumbnailJob.perform_now(video.id, archived, yt_id)
        Import::VideoMediaJob.set(queue: queue).perform_later(video.id, archived, yt_id)

        if publish
          video.listing = 0
          video.publish
        end
        video.save
      end
    end

    def self.create_video(user, yt_id)
      begin
        ProjectVinyl::Web::Youtube.validate_id!(yt_id)
        video = user.videos.create(
          title: "Untitled Import #{yt_id}",
          description: '',
          source: ProjectVinyl::Web::Youtube.video_url(yt_id),
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
          record: video,
          ok: true
        }
      rescue Exception => e
        return {
          response: "Error: Could not schedule action: #{e}",
          ok: false
        }
      end
    end

    def self.query_importable_data(yt_id)
      data = ProjectVinyl::Web::Youtube.get(ProjectVinyl::Web::Youtube.video_url(yt_id), {
        title: true, description: true, artist: true, tags: true
      })
      archived = ProjectVinyl::Web::ThePonyArchive.video_meta(yt_id)

      yield(data, archived)
    end

    def perform(user_id, yt_id)
      Import::VideoJob.create_video(User.find(user_id), yt_id) do |video, data, archived|
        Import::VideoAttributesJob.perform_now(video.id, data, archived, yt_id)
        Import::VideoThumbnailJob.perform_now(video.id, archived, yt_id)
        Import::VideoMediaJob.perform_now(video.id, archived, yt_id)

        video.listing = 0
        video.publish
        video.save
      end
    end
  end
end