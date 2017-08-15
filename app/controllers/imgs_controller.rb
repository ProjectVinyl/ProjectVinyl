class ImgsController < ApplicationController
  # Fallback for assets that don't exist
  
  def avatar
    serve_img('default-avatar')
  end
  
  def banner
    serve_img('banner')
  end
  
  def cover
    serve_img('default-cover')
  end

  def thumb
    png = Rails.root.join('public', 'cover', params[:id]).to_s
    
    if !File.exist?(png + '.png')
      return serve_img('default-cover-small')
    end
    
    Ffmpeg.extract_tiny_thumb_from_existing(png)
    serve_direct("#{png}.png", 'image/png')
  end
  
  def stream
    id = params[:id].split('.')[0]
    
    if !(video = Video.where(id: id).first)
      not_found
    end
    
    if video.hidden
      if !user_signed_in? || !current_user.is_contributor?
        return render file: 'public/403', status: :forbidden, layout: false
      end
    end
    
    ext = video.file
    if params[:id].index('.')
      ext = '.' + params[:id].split('.')[1]
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
    
    response.headers['Content-Length'] = File.size(file.to_s).to_s
    send_file file.to_s, {
      disposition: 'inline',
      type: mime,
      filename: File.basename(file).to_s,
      x_sendfile: true
    }
  end
end
