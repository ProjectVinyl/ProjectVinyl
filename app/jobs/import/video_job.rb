require 'projectvinyl/web/youtube'
require 'projectvinyl/web/youtube_oembed'
require 'projectvinyl/web/the_pony_archive'
require 'projectvinyl/web/ajax'

module Import
  class VideoJob < ApplicationJob
    queue_as :manual

    def self.queue_and_publish_now(user, yt_id, queue = :default, publish: true)
      create_video(user, yt_id) do |video|
        archived = archival_data_for(yt_id)
        Import::VideoAttributesJob.perform_now(video.id, archived, yt_id)
        Import::VideoMediaJob.set(queue: queue).perform_later(video.id, archived, yt_id)
        Import::VideoThumbnailJob.perform_now(video.id, archived, yt_id)

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
        oembed = ProjectVinyl::Web::YoutubeOembed.get(yt_id)
        video = user.videos.create(
          title: oembed[:title] || "Untitled Import #{yt_id}",
          description: '[Pending Import]',
          source: ProjectVinyl::Web::Youtube.video_url(yt_id),
          width: oembed[:thumbnail_width] || 0,
          height: oembed[:thumbnail_height] || 0,
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
          yield(video)
        rescue Exception => e
          video.destroy
          raise e
        end

        @comments = video.create_comment_thread(user: user, title: video.title)
        @comments.subscribe(user) if user.subscribe_on_upload?

        {
          response: 'The video will be imported shortly',
          id: video.id,
          record: video,
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

    def self.data_for(yt_id)
      ProjectVinyl::Web::Youtube.get(ProjectVinyl::Web::Youtube.video_url(yt_id), {
        title: true, description: true, artist: true, tags: true
      })
    end

    def self.archival_data_for(yt_id)
      ProjectVinyl::Web::ThePonyArchive.video_meta(yt_id)
    end

    def perform(user_id, yt_id)
      response = VideoJob.create_video(User.find(user_id), yt_id) do |video|
        archived = VideoJob.archival_data_for(yt_id)
        Import::VideoAttributesJob.perform_now(video.id, archived, yt_id)
        Import::VideoThumbnailJob.perform_now(video.id, archived, yt_id)
        Import::VideoMediaJob.perform_now(video.id, archived, yt_id)

        video.listing = 0
        video.publish
        video.save
      end

      raise response[:response] if !response[:ok]
    end
  end
end
