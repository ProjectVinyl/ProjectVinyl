require 'projectvinyl/web/youtube'
require 'projectvinyl/web/ajax'

class ImportYtVideoJob < ApplicationJob
  queue_as :default

  def self.queue_video(user, video_id, queue = :default)
    begin
      raise 'Invalid length: Id must be 11 characters' if video_id.length != 11
      video = user.videos.create(
        title: "Untitled Import #{video_id}",
        description: '',
        source: "https://www.youtube.com/watch?v=#{video_id}",
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
        ImportYtVideoJob.set(queue: queue).perform_later(video.id, video_id)
      rescue Exception => e
        video.destroy
        raise e
      end

      Video.transaction do
        video.external_sources.create(key: video_id, provider: 'youtube').save
        @comments = video.create_comment_thread(user: user, title: video.title)
        @comments.subscribe(user) if user.subscribe_on_upload?
      end

      {
        response: 'The video will be imported shortly',
        id: video.id,
        ok: true
      }
    rescue Exception => e
      return {
        response: "Error: Could not schedule action: #{e}",
        ok: false
      }
    end
  end

  def perform(video_id, yt_id)
    video = Video.find(video_id)
    url = "https://www.youtube.com/watch?v=#{yt_id}"
    data = ProjectVinyl::Web::Youtube.get(url, {
      title: true, description: true, artist: true, tags: true
    })
    attributes = data[:attributes]

    video.title = attributes[:title]
    video.description = attributes[:description][:bbc]
    video.width = attributes[:dimensions][:width]
    video.height = attributes[:dimensions][:height]
    video.file = '.' + attributes[:extension]
    video.mime = Mimes.mime(video.file)
    video.save

    tags = ((attributes[:included] || {})[:tags] || []).uniq

    if (changes = video.set_all_tags(Tag.create_from_names(tags)))
      TagHistory.record_tag_changes(changes[0], changes[1], video.id, video.user_id)
    end

    ProjectVinyl::Web::Ajax.get("https://i.ytimg.com/vi/#{yt_id}/maxresdefault.jpg") do |body|
      temp = video.cover_path.to_s + '.jpg'
      video.store_file(temp, body)
      Ffmpeg.run_command('-i', temp, video.cover_path) do
        Ffmpeg.extract_tiny_thumb_from_existing(video.cover_path, video.tiny_cover_path)
        File.delete(temp)
      end
    end

    Youtubedl.download_video(url, video.video_path.to_s)

    video.realise_checksum
    video.read_media_attributes
    video.listing = 0
    video.publish
    video.save
    EncodeFilesJob.perform_later(video.id)
  end
end
