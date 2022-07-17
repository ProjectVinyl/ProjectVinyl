module Assets
  module Videos
    class StreamsController < BaseAssetsController
      include ActionController::Live

      def show
        with_video do |video|
          return not_found if !video || !video.visible_to?(current_user)
          return forbidden if !special_access?
          return serve_media_stream video
        end
      end

      private
      def serve_media_stream(video)
        return head :bad_request if params[:format].nil?
        mime = Mimes.mime('.' + params[:format])
        return render status: :bad_request, plain: "Bad Request" if !valid_media_mime?(mime)

        file = locate_matching_file(video, params[:format], mime)
        return serve_direct(file, mime) if file.exist?

        send_file_headers!(
          disposition: 'inline',
          type: mime,
          filename: "#{video.id}_#{video.title}_by_#{video.artist_tags.to_tag_string}.#{params[:format]}"
        )
        response.headers['Last-Modified'] = Time.now.ctime.to_s

        return head :not_found if !video.video_path.exist?

        begin
          Ffstream.produce(video.video_path, params[:format], optimize_for: :speed) do |io|
            if Ffstream.copy_streams(io, response.stream) == 0
              render status: :not_found, plain: 'Format not available for streaming'
              puts "Format not available for streaming: #{params[:format]}"
            end
          end
        ensure
          response.stream.close
        end
      end

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
end
