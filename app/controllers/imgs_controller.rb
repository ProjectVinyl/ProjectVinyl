class ImgsController < ApplicationController
  # Fallback for assets that don't exist
  
  def avatar
    serve_img('default-avatar')
  end
  
  def banner
    serve_img('banner')
  end
  
  def service
    serve_asset('serviceworker.js', 'application/javascript')
  end
  
  def cover
    if !params[:small]
      return serve_img('default-cover')
    end
    
    png = Rails.root.join('public', 'cover', params[:id])
    
    if !File.exist?("#{png}.png")
      return serve_img('default-cover-small')
    end
    
    Ffmpeg.extract_tiny_thumb_from_existing(png)
    serve_direct("#{png}.png", 'image/png')
  end
  
  def stream
    id = params[:id].split('.')[0]
    
    if !(video = Video.where(id: id).first)
      return not_found
    end
    
    if video.hidden && (!user_signed_in? || !current_user.is_contributor?)
      return forbidden
    end
    
    ext = video.file
    if params[:id].index('.')
      ext = ".#{params[:id].split('.')[1]}"
    end
    
    file = ext == '.webm' ? video.webm_path : video.video_path
    mime = ext == '.webm' ? 'video/webm' : video.mime
    serve_direct file, mime
  end
  
  private
  def serve_img(file_name)
    serve_direct "#{Rails.root.join('public', 'images', file_name)}.png", 'image/png'
  end
  
  def serve_direct(file, mime)
    if !File.exist?(file)
      not_found
    end
    
    response.headers['Content-Length'] = File.size(file).to_s
    send_file file.to_s, {
      disposition: 'inline',
      type: mime,
      filename: File.basename(file).to_s,
      x_sendfile: true
    }
  end
  
  def serve_asset(asset, mime)
  	response.headers['Content-Type'] = mime
    render plain: Rails.application.assets[asset].to_s
  end
end
