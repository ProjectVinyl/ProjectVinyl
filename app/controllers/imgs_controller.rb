class ImgsController < ApplicationController
#Fallback for assets that don't exist
  def cover
    serveRaw(Rails.root.join('public', 'images', 'default-cover'), 'png', 'image')
  end
  
  def thumb
    png = Rails.root.join('public', 'cover', params[:id]).to_s
    if File.exists?(png + '.png')
      Ffmpeg.extractTinyThumbFromExisting(png)
      serveRaw(png, 'png', 'image')
      return
    end
    serveRaw(Rails.root.join('public', 'images', 'default-cover-small'), 'png', 'image')
  end
  
  def avatar
    serveRaw(Rails.root.join('public', 'images', 'default-avatar'), 'png', 'image')
  end
  
  def banner
    serveRaw(Rails.root.join('public', 'images', 'banner'), 'png', 'image')
  end
  
  def stream
    id = params[:id].split('.')[0]
    if (video = Video.where(id: id).first) && video.hidden
       if user_signed_in? && current_user.is_admin
         ext = video.file
         if params[:id].index('.')
           ext = '.' + params[:id].split('.')[1]
         end
         serveDirect(ext == '.webm' ? video.webm_path : video.video_path, ext == '.webm' ? 'video/webm' : video.mime)
       else
         render :file => 'public/403.html',  status: 403, :layout => false
       end
    else
      render :file => 'public/404.html', :status => :not_found, :layout => false
    end
  end
  
  private
  def serveRaw(file, ext, type)
    serveDirect(file.to_s + "." + ext, type + "/" + ext)
  end
  def serveDirect(file, mime)
    response.headers['Content-Length'] = File.size(file.to_s).to_s
    send_file file.to_s, :disposition => 'inline', :type => mime, :filename => File.basename(file).to_s, :x_sendfile => true
  end
end
