module Videos
  class DownloadsController < BaseVideosController
    def show
      return not_found if !(@video = Video.where(id: params[:video_id]).first)

      if @video.duplicate_id > 0
        @video = Video.where(id: @video.duplicate_id).first
      end

      return forbidden if @video.hidden && !(user_signed_in? && @video.owned_by(current_user))

      file = get_file(@video, params[:format]).to_s
      return not_found if !File.exist?(file)

      response.headers['Content-Length'] = File.size(file).to_s
      send_file(file,
        filename: "#{@video.id}_#{@video.title}_by_#{@video.artists_string}#{File.extname(file)}",
        type: @video.mime
      )
    end

    def get_file(video, format)
      return video.video_path if video.file == '.' + format
      return video.webm_path if format == 'webm'
      return video.audio_path if format == 'mp3'
      return video.mpeg_path if format == 'mp4'
      ''
    end
  end
end
