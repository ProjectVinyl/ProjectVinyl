module Assetable

  def serve_img(file_name)
    serve_direct "#{Rails.root.join('public', 'images', file_name)}", 'image/png'
  end

  def serve_direct(file, mime)
    not_found if !File.exist?(file)

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

    return render plain: Rails.application.assets[asset].to_s if Rails.application.assets

    file = Rails.application.assets_manifest.assets[asset]

    not_found if !file

    file = File.join(Rails.application.assets_manifest.dir, file)
    serve_direct(file, mime)
  end
  
  def valid_media_mime?(mime)
    !mime.nil? && !['audio', 'video'].index(mime.split('/').first).nil?
  end
end
