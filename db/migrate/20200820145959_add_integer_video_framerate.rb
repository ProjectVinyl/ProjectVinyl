class AddIntegerVideoFramerate < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :framerate, :integer

    Video.reset_column_information
    Video.where(audio_only: false).find_each(batch_size: 1000) do |video|
      video.framerate = video.has_video? ? Ffprobe.framerate(video.video_path) : 1
      video.save
    end
  end
end
