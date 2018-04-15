class ProcessVideoJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find(video_id)
    
    if video.audio_only
      video.set_status(true)
      return
    end
    
    video.set_status(false)
    return Ffmpeg.produce_webm(video.video_path) do
      video.set_status(true)
    end
  end
end
