class ImgsController < ApplicationController
  
  def download
    @video = Video.find(params[:id].split(/-/)[0])
    send_file("#{Rails.root}/public/stream/#{@video.id}.#{(@video.audio_only ? 'mp3' : 'mp4')}",
        :filename => "#{@video.id}_#{@video.title}_by_#{@video.artist.name}.#{(@video.audio_only ? 'mp3' : 'mp4')}",
        :type => @video.mime
    )
  end
  
end
