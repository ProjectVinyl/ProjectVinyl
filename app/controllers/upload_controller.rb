class UploadController < ApplicationController
  def avatar
    uploaded_io = params[:author][:avatar]
    File.open(Rails.root.join('public', 'avatar', params[:author][:id]) do |file|
      file.write(uploaded_io.read)
      @artist = Artist.find(params[:artist][:id])
      @artist.mime = uploaded_io.content_type
      @artist.save
    end
  end
  
  def song
    uploaded_io = params[:video][:file]
    @video = Video.find(params[:video][:id])
    path = Rails.root.join('public', 'stream', video.id + (video.audio_only ? '.mp3' : '.mp4')
    File.open(path) do |file|
      file.write(uploaded_io.read)
      @video.mime = uploaded_io.content_type
      @video.save
      Ffmpeg.produceWebM(path.to_s)
  end
  
  def cover
    uploaded_io = params[:video][:cover]
    File.open(Rails.root.join('public', 'cover', params[:video][:id]) do |file|
      file.write(uploaded_io.read)
  end
end
