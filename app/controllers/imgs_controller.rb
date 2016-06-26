class ImgsController < ApplicationController
#Fallback for assets that don't exist
  def cover
    old = Rails.root.join('public', 'cover', params[:id])
    if File.exists?(old)
      File.rename(old, old.to_s + '.png')
      serveRaw(old, 'png', 'image')
      return
    end
    serveRaw(Rails.root.join('public', 'images', 'default-cover'), 'png', 'image')
  end
  
  def avatar
    serveRaw(Rails.root.join('public', 'images', 'default-avatar'), 'png', 'image')
  end
  
  def stream
   # if (video = Video.where(id: params[:id]).first) && !video.hidden
   #    serveRaw(Rails.root.join('public', 'stream', params[:id]), video.file, video.audio_only ? 'audio' : 'video')
   # else
       render status: 404, nothing: true
   # end
  end
  
  private
  def serveFile(file, defau, ext, type)
    file = Rails.root.join('storage', file)
    if File.exists? file + "." + ext
      serveRaw(file, ext, type)
    else
      serveRaw(defau, ext, type)
    end
  end
  def serveRaw(file, ext, type)
    response.headers['Content-Length'] = File.size(file.to_s + "." + ext).to_s
    send_file file.to_s + "." + ext, :disposition => 'inline', :type => type + "/" + ext, :filename => File.basename(file).to_s + '.' + ext, :x_sendfile => true
  end
end
