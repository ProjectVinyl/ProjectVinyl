class UploadController < ApplicationController
  def avatar
    uploaded_io = params[:author][:avatar]
    File.open(Rails.root.join('public', 'avatar', params[:author][:id], 'wb') do |file|
      file.write(uploaded_io.read)
      Artist.find(params[:artist][:id]).mime = uploaded_io.content_type
    end
  end
  
  def song
    uploaded_io = params[:video][:file]
    File.open(Rails.root.join('public', 'stream', params[:video][:id], 'wb') do |file|
      file.write(uploaded_io.read)
      Video.find(params[:video][:id]).mime = uploaded_io.content_type
  end
  
  def cover
    uploaded_io = params[:video][:cover]
    File.open(Rails.root.join('public', 'stream', params[:video][:id], 'wb') do |file|
      file.write(uploaded_io.read)
      Video.find(params[:video][:id]).mime = uploaded_io.content_type
  end
end
