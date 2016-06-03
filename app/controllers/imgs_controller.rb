class ImgsController < ApplicationController
#Fallback for assets that don't exist
  def cover
    serveRaw(Rails.root.join('public', 'images', 'avatar', 'none.jpg'), 'jpg', 'image/jpg')
  end
  
  def avatar
    serveRaw(Rails.root.join('public', 'images', 'avatar', 'none.jpg'), 'jpg', 'image/jpg')
  end
  
  def stream
    if video = Video.where(id: params[:id]).first
       serveRaw(Rails.root.join('public', 'stream', params[:id]).to_s + (video.audio_only ? '.mp3' : '.mp4'), '', (video.audio_only ? 'audio/mp3' : 'audio/mp4'))
    else
       render status: 404
    end
  end
  
  private
  def serveFile(id, path, ext, defau)
    file = Rails.root.join('storage', path, id)
    if File.exists? file
      serveRaw file, ext, 'image/' + ext
    else
      serveRaw defau, ext, 'image/' + ext
    end
  end
  
  def serveRaw(file, ext, type)
    response.headers['Content-Length'] = File.size(file).to_s
    send_file file, :disposition => 'inline', :type => type, :filename => File.basename(file).to_s + '.' + ext, :x_sendfile => true
  end
end
