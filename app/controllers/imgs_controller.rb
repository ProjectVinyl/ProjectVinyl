class ImgsController < ApplicationController
  def avatar
    @artist = Artist.find(params[:id])
    send_data(@artist.avatar, :type => @artist.mime, :filename => @artist.id, :disposition => "inline")
  end
  
  def cover
    @video = Video.find(params[:id])
    send_data(@video.cover, :type => @video.mime, :filename => @video.id, :disposition => "inline")
  end

  def stream
    @video = Video.find(params[:id])
    send_data(@video.file, :filename => "{@video.id}-{@video.title}.mp4", :disposition => "inline")
  end
  
  def download
    @video = Video.find(params[:id])
    send_data(@video.file, :filename => "{@video.id}-{@video.title}.mp4", :disposition => "download")
  end
end
