class UploadController < ApplicationController
  def avatar
    uploaded_io = params[:author][:avatar]
    File.open(Rails.root.join('public', 'avatar', params[:author][:id], 'wb') do |file|
      file.write(uploaded_io.read)
      @artist = Artist.find(params[:artist][:id])
      @artist.mime = uploaded_io.content_type
      @artist.save
    end
  end
  
  def song
    uploaded_io = params[:video][:file]
    File.open(Rails.root.join('public', 'stream', params[:video][:id], 'wb') do |file|
      file.write(uploaded_io.read)
      @video = Video.find(params[:video][:id])
      @video.mime = uploaded_io.content_type
      @video.save
  end
  
  def cover
    uploaded_io = params[:video][:cover]
    File.open(Rails.root.join('public', 'cover', params[:video][:id], 'wb') do |file|
      file.write(uploaded_io.read)
  end
end
