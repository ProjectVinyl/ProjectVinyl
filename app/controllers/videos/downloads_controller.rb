module Videos
  class DownloadsController < BaseVideosController
    include ActionController::Live
    include Assetable

    def show
      return head :bad_request if params[:format].nil?
      mime = Mimes.mime('.' + params[:format])
      return render status: :bad_request, plain: "Bad Request" if !valid_media_mime?(mime)

      if !(@video = Video.where(id: params[:video_id]).first)
        return render status: :not_found, plain: "Not Found"
      end

      @video = Video.where(id: @video.duplicate_id).first if @video.duplicate_id > 0

      return head :forbidden if @video.hidden && !(user_signed_in? && @video.owned_by(current_user))

      sent_file_name = "#{@video.id}_#{@video.title}_by_#{@video.artist_tags.to_tag_string}.#{params[:format]}"

      file = locate_matching_file(@video, params[:format], mime)
      if file.exist?
        response.headers['Content-Length'] = file.size.to_s
        return send_file(file,
          filename: sent_file_name,
          type: mime
        )
      end

      send_file_headers!(filename: sent_file_name, type: mime)
      response.headers['Last-Modified'] = Time.now.ctime.to_s

      return head :not_found if !@video.video_path.exist?

      begin
        Ffstream.produce(@video.video_path, params[:format], optimize_for: :quality) do |io|
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
    def locate_matching_file(video, format, mime)
      return video.video_path if video.file == '.' + format
      return video.webm_path if format == 'webm'
      return video.audio_path if format == 'mp3'
      return video.mpeg_path if format == 'mp4'

      filename = mime.split('/')[0]
      video.absolute_storage_path + "#{filename}.#{format}"
    end
  end
end
