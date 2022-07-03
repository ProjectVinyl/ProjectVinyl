module Videos
  class DownloadsController < BaseVideosController
    include ActionController::Live

    def show
      return head :bad_request if params[:format].nil?
      mime = Mimes.mime('.' + params[:format])
      if mime.nil? || ['audio', 'video'].index(mime.split('/').first).nil?
        return render status: :bad_request, plain: "Bad Request"
      end
      if !(@video = Video.where(id: params[:video_id]).first)
        return render status: :not_found, plain: "Not Found"
      end

      @video = Video.where(id: @video.duplicate_id).first if @video.duplicate_id > 0

      return head :forbidden if @video.hidden && !(user_signed_in? && @video.owned_by(current_user))

      file = get_file(@video, params[:format], mime)
      if false && file.exist?
        response.headers['Content-Length'] = file.size.to_s
        return send_file(file,
          filename: "#{@video.id}_#{@video.title}_by_#{@video.artist_tags.to_tag_string}#{file.extname}",
          type: mime
        )
      end

      send_file_headers!(
        filename: "#{@video.id}_#{@video.title}_by_#{@video.artist_tags.to_tag_string}.#{params[:format]}",
        type: mime
      )

      begin
        Ffstream.produce(@video.video_path, params[:format]) do |io|
          if Ffstream.copy_streams(io, response.stream) == 0
            render status: :not_found, plain: 'Format not available for streaming'
            puts "Format not available for streaming: #{params[:format]}"
          end
        end
      ensure
        response.stream.close
      end
    end

    private
    def get_file(video, format, mime)
      return video.video_path if video.file == '.' + format
      return video.webm_path if format == 'webm'
      return video.audio_path if format == 'mp3'
      return video.mpeg_path if format == 'mp4'

      filename = mime.split('/')[0]
      video.absolute_storage_path + "#{filename}.#{format}"
    end
  end
end
