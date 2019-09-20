module Assets
  class StreamController < ApplicationController
    include Assetable

    def show
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
  end
end