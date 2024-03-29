module Videos
  class MediaController < Videos::BaseVideosController
    def update
      return api_error_response('Access Denied', 'You can\'t do that right now.') if !user_signed_in?
      return api_error_response('Read Only', 'That feature is currently disabled.') if ApplicationHelper.read_only && !current_user.is_contributor?

      if !(@video = Video.where(id: params[:video_id]).first)
        return api_error_response('404', 'Resource not found.')
      end

      return api_error_response('Access Denied', 'Resource cannot be modified') if @video.user_id != current_user.id && !current_user.is_staff?
      return api_error_response('Access Denied', 'Resource cannot be modified.') if @video.user_id == current_user.id && !@video.draft

      file = params[:video][:file]
      checksum = Verification::VideoVerification.ensure_uniq(file.read, @video.id)
      return api_error_response('Duplication Error', 'The uploaded video already exists.') if !checksum[:valid]

      @video.upload_media(file, checksum)
      @video.save

      Encode::VideoJob.queue_video(@video, queue: :manual)

      render json: {
        success: true,
        upload_id: @video.id,
        params: @video.thumb_picker_header
      }
    end
  end
end
