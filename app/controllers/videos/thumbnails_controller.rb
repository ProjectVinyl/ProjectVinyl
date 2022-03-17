module Videos
  class ThumbnailsController < Videos::BaseVideosController
    def update
      return api_error_response('Access Denied', 'You can\'t do that right now.') if !user_signed_in?
      return api_error_response('Read Only', 'That feature is currently disabled.') if ApplicationHelper.read_only && !current_user.is_contributor?

      if !(@video = Video.where(id: params[:video_id]).first)
        return api_error_response('404', 'Resource not found.')
      end

      return api_error_response('Access Denied', 'Resource cannot be modified') if @video.user_id != current_user.id && !current_user.is_staff?
      return api_error_response('Access Denied', 'Resource cannot be modified.') if @video.user_id == current_user.id && !@video.draft

      cover = params[:video][:cover]
      time = params[:video][:time].to_i

      time = nil if !cover.nil?

      has_cover = cover && cover.size > 0 && cover.content_type.include?('image/')

      return api_error_response('Error', 'Cover art is required for audio files.') if @video.audio_only && !has_cover

      ExtractThumbnailJob.queue_video(@video, cover, time, queue: :manual)

      render json: {
        success: true,
        upload_id: @video.id,
        params: @video.thumb_picker_header
      }
    end
  end
end
