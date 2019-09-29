class ProcessVideoJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find(video_id)
    
    if video.audio_only
      video.set_status(true)
      return
    end
    
    video.set_status(false)
    Ffmpeg.produce_webm(video, video.video_path, video.webm_path) do
      video = Video.find(video_id)
      video.set_status(true)
      video.update_file_locations
    end
  end
end
