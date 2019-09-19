module Videos
  class DownloadsController < BaseVideosController
    def show
      if !(@video = Video.where(id: params[:video_id]).first)
        return not_found
      end

      if @video.duplicate_id > 0
        @video = Video.where(id: @video.duplicate_id).first
      end

      if @video.hidden && !(user_signed_in? && @video.owned_by(current_user))
        return forbidden
      end

      file = @video.video_path.to_s
      if !File.exist?(file)
        return not_found
      end

      response.headers['Content-Length'] = File.size(file).to_s
      send_file(file,
        filename: "#{@video.id}_#{@video.title}_by_#{@video.artists_string}#{@video.file}",
        type: @video.mime
      )
    end
  end
end
