module Assets
  class StreamController < ApplicationController
    include Assetable

    def show
      id = params[:id].split('.')[0]

      if (video = Video.where(id: id).first)

        if video.hidden
          if !(user_signed_in? && current_user.is_contributor?)

            if params[:file_name] == 'cover'
              return redirect_to '/images/default-cover-g.png'
            end

            if params[:file_name] == 'thumb'
              return redirect_to '/images/default-cover-small-g.png'
            end

            return forbidden
          end

          if params[:file_name] == 'video' || params[:file_name] == 'audio' || params[:file_name] == 'source'
            path = video.video_path

            if File.exist?(path)
              serve_direct path, video.mime
            end
          end
        end

        if params[:file_name] == 'thumb'
          png = video.cover_path

          if File.exist?(png)
            Ffmpeg.extract_tiny_thumb_from_existing(png, video.tiny_cover_path)

            return serve_direct(png, 'image/png')
          end
        end
      end

      if params[:file_name] == 'cover'
        return redirect_to '/images/default-cover.png'
      end

      if params[:file_name] == 'thumb'
        return redirect_to '/images/default-cover-small.png'
      end

      return not_found
    end
  end
end